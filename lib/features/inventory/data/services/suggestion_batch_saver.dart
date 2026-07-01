import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../../../core/utils/money.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/item_suggestion.dart';
import '../../domain/entities/photo.dart';
import '../../domain/repositories/item_repository.dart';
import '../../../../services/import/import_fallback_seeder.dart';

const _uuid = Uuid();

/// Matches `PhotoController.addPhoto` so both review flows can hand the
/// saver their real photo path as a tear-off.
typedef AddPhoto =
    Future<bool> Function({
      required String itemId,
      required Uint8List bytes,
      required PhotoSource source,
      bool setAsPrimary,
    });

/// One accepted suggestion, ready to persist. [photoBytes] is the image
/// that attaches to the created item — the full shelf photo for shelf
/// review, the item's source frame for video review — with [photoSource]
/// saying honestly where it came from.
class SuggestionSaveEntry {
  final String name;
  final ItemSuggestion suggestion;
  final String? categoryIdOverride;
  final bool hasCategoryOverride;
  final Uint8List? photoBytes;
  final PhotoSource photoSource;

  const SuggestionSaveEntry({
    required this.name,
    required this.suggestion,
    this.categoryIdOverride,
    this.hasCategoryOverride = false,
    required this.photoBytes,
    required this.photoSource,
  });
}

/// The one batch-save path for AI-suggested items — extracted from
/// ShelfReviewScreen so video review saves through the same tested code
/// instead of a copy. Money is always rounded to cents; a failed photo
/// write never loses the item itself.
class SuggestionBatchSaver {
  final ItemRepository _repo;
  final ImportFallbackSeeder _seeder;
  final AddPhoto _addPhoto;

  SuggestionBatchSaver({
    required ItemRepository itemRepository,
    required ImportFallbackSeeder seeder,
    required AddPhoto addPhoto,
  }) : _repo = itemRepository,
       _seeder = seeder,
       _addPhoto = addPhoto;

  /// Persists [entries]; returns how many items were actually created
  /// and how many FAILED — the caller's snackbar must be able to say
  /// "Added 3 of 10" instead of letting failures vanish. Blank names
  /// are skipped (neither saved nor failed), batch [roomId]/[containerId]
  /// apply to every entry, and missing category/room fall back to seeded
  /// defaults.
  Future<({int saved, int failed})> saveAll({
    required List<SuggestionSaveEntry> entries,
    required List<Category> categories,
    String? roomId,
    String? containerId,
    String? creatorProfileId,
  }) async {
    final (fallbackCategoryId, fallbackRoomId) = await _seeder.ensureDefaults();

    var saved = 0;
    var failed = 0;
    for (final entry in entries) {
      final name = entry.name.trim();
      if (name.isEmpty) continue;

      final suggestion = entry.suggestion;
      final entity = Item(
        id: _uuid.v4(),
        name: name,
        description: '',
        categoryId: _resolveCategoryId(entry, categories, fallbackCategoryId),
        roomId: roomId ?? fallbackRoomId,
        containerId: containerId,
        brand: suggestion.brand,
        model: suggestion.model,
        // The suggestion wire speaks dollars; storage is cents.
        currentValueCents: centsFromDollarsOrNull(suggestion.estimatedValue),
        isInsured: false,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        creatorProfileId: creatorProfileId,
      );

      // estimatedValue is verbatim LLM output — its price-history row
      // must say so, not claim the user typed it.
      final result = await _repo.createItem(
        entity,
        priceSource: 'llm_estimate',
      );
      await result.when(
        success: (_) async {
          saved++;
          // The photo attaches to the accepted item; a failed photo
          // write must not lose the item itself.
          final bytes = entry.photoBytes;
          if (bytes != null) {
            await _addPhoto(
              itemId: entity.id,
              bytes: bytes,
              source: entry.photoSource,
              setAsPrimary: true,
            );
          }
        },
        failure: (_) async {
          failed++;
        },
      );
    }
    return (saved: saved, failed: failed);
  }

  /// Resolves an entry's category: explicit user override first, then a
  /// case-insensitive name match (exact, then prefix — "Books" should hit
  /// "Books & Media"), then the Imports fallback.
  String _resolveCategoryId(
    SuggestionSaveEntry entry,
    List<Category> categories,
    String fallbackId,
  ) {
    if (entry.hasCategoryOverride) {
      return entry.categoryIdOverride ?? fallbackId;
    }
    final hint = entry.suggestion.categoryName?.trim().toLowerCase();
    if (hint != null && hint.isNotEmpty) {
      final exact = categories
          .where((c) => c.name.toLowerCase() == hint)
          .firstOrNull;
      if (exact != null) return exact.id;
      final prefix = categories
          .where((c) => c.name.toLowerCase().startsWith(hint))
          .firstOrNull;
      if (prefix != null) return prefix.id;
    }
    return fallbackId;
  }
}

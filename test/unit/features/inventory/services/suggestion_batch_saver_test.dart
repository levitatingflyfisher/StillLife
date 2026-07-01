import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/inventory/data/repositories/item_repository_impl.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart'
    as domain_item;
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/data/services/suggestion_batch_saver.dart';
import 'package:still_life/features/inventory/domain/entities/category.dart'
    as domain;
import 'package:still_life/features/inventory/domain/entities/item_suggestion.dart';
import 'package:still_life/features/inventory/domain/entities/photo.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/import/import_fallback_seeder.dart';
import 'package:still_life/services/storage/photo_storage_service.dart';

import '../../../../test_setup.dart';

/// Records addPhoto calls instead of persisting — the saver's contract is
/// "called once per saved item with the right bytes/source", not "photos
/// table row exists" (that is PhotoController's own tested job).
/// Delegates to the real repo but fails any item named 'FAILS' — the
/// saver's contract is that per-item failures are COUNTED, not dropped.
class _FlakyRepo extends Fake implements ItemRepository {
  final ItemRepository inner;
  _FlakyRepo(this.inner);

  @override
  Future<Result<domain_item.Item>> createItem(
    domain_item.Item item, {
    String priceSource = 'manual',
  }) async {
    if (item.name == 'FAILS') {
      return const Err(DatabaseFailure('database is locked'));
    }
    return inner.createItem(item, priceSource: priceSource);
  }
}

class _PhotoCall {
  final String itemId;
  final Uint8List bytes;
  final PhotoSource source;
  final bool setAsPrimary;
  _PhotoCall(this.itemId, this.bytes, this.source, this.setAsPrimary);
}

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late SuggestionBatchSaver saver;
  late List<_PhotoCall> photoCalls;
  late List<domain.Category> categories;

  setUp(() async {
    db = AppDatabase.memory();
    photoCalls = [];
    final now = DateTime(2026);
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat-tools', name: 'Tools', createdAt: now, modifiedAt: now));
    categories = [
      domain.Category(
        id: 'cat-tools',
        name: 'Tools',
        createdAt: now,
        modifiedAt: now,
      ),
    ];
    saver = SuggestionBatchSaver(
      itemRepository: ItemRepositoryImpl(db, PhotoStorageService()),
      seeder: ImportFallbackSeeder(database: db),
      addPhoto: ({
        required String itemId,
        required Uint8List bytes,
        required PhotoSource source,
        bool setAsPrimary = false,
      }) async {
        photoCalls.add(_PhotoCall(itemId, bytes, source, setAsPrimary));
        return true;
      },
    );
  });

  tearDown(() => db.close());

  test('saves entries with brand/model and money rounded to cents', () async {
    final saved = await saver.saveAll(
      entries: [
        SuggestionSaveEntry(
          name: 'Cordless drill',
          suggestion: const ItemSuggestion(
            brand: 'Bosch',
            model: 'GSB 18V',
            categoryName: 'tools',
            estimatedValue: 123.456789,
          ),
          photoBytes: Uint8List.fromList([9, 9]),
          photoSource: PhotoSource.videoFrame,
        ),
      ],
      categories: categories,
    );

    expect(saved.saved, 1);
    final item = await db.select(db.items).getSingle();
    expect(item.name, 'Cordless drill');
    expect(item.brand, 'Bosch');
    expect(item.model, 'GSB 18V');
    expect(item.currentValueCents, 12346);
    expect(item.categoryId, 'cat-tools');
  });

  test('half-cent boundary rounds up (1.005 → 1.01), not down', () async {
    // 1.005's nearest double is 1.00499999999999989 — naive
    // (v*100).round()/100 writes 1.00. The rounding law says 1.01.
    await saver.saveAll(
      entries: [
        const SuggestionSaveEntry(
          name: 'Half-cent widget',
          suggestion: ItemSuggestion(estimatedValue: 1.005),
          photoBytes: null,
          photoSource: PhotoSource.videoFrame,
        ),
      ],
      categories: categories,
    );
    final item = await db.select(db.items).getSingle();
    expect(item.currentValueCents, 101);
  });

  test('reports per-item failures instead of silently dropping them — '
      '"Added 3" after accepting 10 must not hide 7 failures', () async {
    final flakySaver = SuggestionBatchSaver(
      itemRepository: _FlakyRepo(ItemRepositoryImpl(db, PhotoStorageService())),
      seeder: ImportFallbackSeeder(database: db),
      addPhoto: ({
        required String itemId,
        required Uint8List bytes,
        required PhotoSource source,
        bool setAsPrimary = false,
      }) async => true,
    );

    final result = await flakySaver.saveAll(
      entries: [
        const SuggestionSaveEntry(
          name: 'Cordless drill',
          suggestion: ItemSuggestion(),
          photoBytes: null,
          photoSource: PhotoSource.camera,
        ),
        const SuggestionSaveEntry(
          name: 'FAILS',
          suggestion: ItemSuggestion(),
          photoBytes: null,
          photoSource: PhotoSource.camera,
        ),
      ],
      categories: categories,
    );

    expect(result.saved, 1);
    expect(result.failed, 1,
        reason: 'a Result.failure per item must surface in the tally');
  });

  test('records LLM-estimated prices with llm_estimate provenance, not '
      'manual', () async {
    await saver.saveAll(
      entries: [
        const SuggestionSaveEntry(
          name: 'Cordless drill',
          suggestion: ItemSuggestion(estimatedValue: 99.99),
          photoBytes: null,
          photoSource: PhotoSource.videoFrame,
        ),
      ],
      categories: categories,
    );

    final rows = await db.select(db.priceHistoryEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.source, 'llm_estimate',
        reason: 'the chart shows where the number came from — a price the '
            'model hallucinated must never masquerade as user-entered');
  });

  test('attaches the entry photo with its declared source', () async {
    await saver.saveAll(
      entries: [
        SuggestionSaveEntry(
          name: 'Couch',
          suggestion: const ItemSuggestion(),
          photoBytes: Uint8List.fromList([1, 2, 3]),
          photoSource: PhotoSource.videoFrame,
        ),
      ],
      categories: categories,
    );

    expect(photoCalls, hasLength(1));
    expect(photoCalls.single.bytes, Uint8List.fromList([1, 2, 3]));
    expect(photoCalls.single.source, PhotoSource.videoFrame);
    expect(photoCalls.single.setAsPrimary, true);
  });

  test('skips blank names and entries without photos skip addPhoto',
      () async {
    final saved = await saver.saveAll(
      entries: [
        SuggestionSaveEntry(
          name: '   ',
          suggestion: const ItemSuggestion(),
          photoBytes: Uint8List.fromList([1]),
          photoSource: PhotoSource.camera,
        ),
        const SuggestionSaveEntry(
          name: 'Lamp',
          suggestion: ItemSuggestion(),
          photoBytes: null,
          photoSource: PhotoSource.camera,
        ),
      ],
      categories: categories,
    );

    expect(saved.saved, 1);
    expect(photoCalls, isEmpty);
    final item = await db.select(db.items).getSingle();
    expect(item.name, 'Lamp');
  });

  test('uses the batch room and container, falling back to seeded room',
      () async {
    final now = DateTime(2026);
    await db.into(db.properties).insert(PropertiesCompanion.insert(
        id: 'prop-1', name: 'Home', createdAt: now, modifiedAt: now));
    await db.into(db.rooms).insert(RoomsCompanion.insert(
        id: 'room-1',
        propertyId: 'prop-1',
        name: 'Garage',
        createdAt: now,
        modifiedAt: now));
    await db.into(db.storageContainers).insert(
        StorageContainersCompanion.insert(
            id: 'cont-1',
            roomId: 'room-1',
            name: 'Shelf A',
            createdAt: now,
            modifiedAt: now));

    await saver.saveAll(
      entries: [
        const SuggestionSaveEntry(
          name: 'Toolbox',
          suggestion: ItemSuggestion(),
          photoBytes: null,
          photoSource: PhotoSource.camera,
        ),
      ],
      categories: categories,
      roomId: 'room-1',
      containerId: 'cont-1',
    );

    final item = await db.select(db.items).getSingle();
    expect(item.roomId, 'room-1');
    expect(item.containerId, 'cont-1');
  });

  test('explicit category override beats the suggestion hint', () async {
    final now = DateTime(2026);
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat-elec',
        name: 'Electronics',
        createdAt: now,
        modifiedAt: now));
    categories = [
      ...categories,
      domain.Category(
        id: 'cat-elec',
        name: 'Electronics',
        createdAt: now,
        modifiedAt: now,
      ),
    ];

    await saver.saveAll(
      entries: [
        const SuggestionSaveEntry(
          name: 'Drill',
          suggestion: ItemSuggestion(categoryName: 'Tools'),
          categoryIdOverride: 'cat-elec',
          hasCategoryOverride: true,
          photoBytes: null,
          photoSource: PhotoSource.camera,
        ),
      ],
      categories: categories,
    );

    final item = await db.select(db.items).getSingle();
    expect(item.categoryId, 'cat-elec');
  });
}

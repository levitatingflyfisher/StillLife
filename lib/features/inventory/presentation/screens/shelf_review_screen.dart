import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../locations/domain/entities/room.dart';
import '../../../locations/domain/entities/storage_container.dart';
import '../../../locations/presentation/controllers/location_controller.dart';
import '../../data/services/suggestion_batch_saver.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/item_suggestion.dart';
import '../../domain/entities/photo.dart';
import '../controllers/category_controller.dart';
import '../controllers/photo_controller.dart';

/// Arguments for the shelf-review route: the per-item suggestions plus the
/// FULL-frame shelf photo that attaches to every accepted item — no fake
/// per-item cropping is performed.
class ShelfReviewArgs {
  final List<ItemSuggestion> suggestions;
  final Uint8List photoBytes;
  final String? roomId;
  final String? containerId;

  const ShelfReviewArgs({
    required this.suggestions,
    required this.photoBytes,
    this.roomId,
    this.containerId,
  });
}

/// Screen for reviewing the items an LLM spotted in one shelf/room photo
/// before saving them to the inventory. Mirrors the ImportReviewScreen
/// idioms: checkbox per row (default accepted), inline name edit, batch
/// room/container pickers, fallback seeding for category/room defaults.
class ShelfReviewScreen extends ConsumerStatefulWidget {
  final ShelfReviewArgs args;

  const ShelfReviewScreen({super.key, required this.args});

  @override
  ConsumerState<ShelfReviewScreen> createState() => _ShelfReviewScreenState();
}

/// Mutable per-suggestion review state. Ephemeral — never persisted.
class _ShelfEntry {
  final ItemSuggestion suggestion;
  final TextEditingController nameController;
  bool accepted;
  String? categoryIdOverride;
  bool hasCategoryOverride;

  _ShelfEntry(this.suggestion)
      : nameController = TextEditingController(text: suggestion.name ?? ''),
        accepted = true,
        categoryIdOverride = null,
        hasCategoryOverride = false;
}

class _ShelfReviewScreenState extends ConsumerState<ShelfReviewScreen> {
  late final List<_ShelfEntry> _entries;
  String? _roomId;
  String? _containerId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.args.suggestions.map(_ShelfEntry.new).toList();
    _roomId = widget.args.roomId;
    _containerId = widget.args.containerId;
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.nameController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // The shared batch-save path (also used by video review): category
      // resolution, cents rounding, and photo attach live there.
      final saver = SuggestionBatchSaver(
        itemRepository: ref.read(itemRepositoryProvider),
        seeder: ref.read(importFallbackSeederProvider),
        addPhoto: ref.read(photoControllerProvider.notifier).addPhoto,
      );

      final result = await saver.saveAll(
        entries: [
          for (final entry in _entries)
            if (entry.accepted)
              SuggestionSaveEntry(
                name: entry.nameController.text,
                suggestion: entry.suggestion,
                categoryIdOverride: entry.categoryIdOverride,
                hasCategoryOverride: entry.hasCategoryOverride,
                // The full shelf frame attaches to every accepted item.
                photoBytes: widget.args.photoBytes,
                photoSource: PhotoSource.camera,
              ),
        ],
        categories: ref.read(categoriesProvider).valueOrNull ?? <Category>[],
        roomId: _roomId,
        containerId: _containerId,
        creatorProfileId: ref.read(activeProfileProvider).valueOrNull?.id,
      );

      if (mounted) {
        final saved = result.saved;
        final message = result.failed > 0
            ? 'Added $saved of ${saved + result.failed} items — '
                  '${result.failed} failed'
            : 'Added $saved item${saved == 1 ? '' : 's'}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        context.pop();
      }
    } catch (e) {
      // A thrown save (locked/full DB) must not vanish into the zone —
      // the user needs to know nothing (or not everything) was saved.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCategorySheet(_ShelfEntry entry, List<Category> categories) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          ListTile(
            title: const Text('Uncategorized'),
            onTap: () {
              setState(() {
                entry.categoryIdOverride = null;
                entry.hasCategoryOverride = true;
              });
              Navigator.of(ctx).pop();
            },
          ),
          ...categories.map((cat) {
            final isHint =
                entry.suggestion.categoryName != null &&
                cat.name.toLowerCase() ==
                    entry.suggestion.categoryName!.toLowerCase();
            return ListTile(
              title: Text(cat.name),
              trailing: isHint
                  ? const Icon(Icons.auto_awesome_outlined, size: 16)
                  : null,
              onTap: () {
                setState(() {
                  entry.categoryIdOverride = cat.id;
                  entry.hasCategoryOverride = true;
                });
                Navigator.of(ctx).pop();
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(allRoomsProvider).valueOrNull ?? <Room>[];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? <Category>[];
    final containers = _roomId == null
        ? <StorageContainer>[]
        : ref.watch(containersInRoomProvider(_roomId!)).valueOrNull ??
              <StorageContainer>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Shelf (${_entries.length})'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Save All'),
            onPressed: _isSaving ? null : _saveAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: OhSpacing.insetSm,
            child: Column(
              children: [
                if (rooms.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _roomId,
                    hint: const Text('Room for all items'),
                    items: [
                      for (final r in rooms)
                        DropdownMenuItem(value: r.id, child: Text(r.name)),
                    ],
                    onChanged: (v) => setState(() {
                      _roomId = v;
                      // Containers belong to a room; switching rooms
                      // invalidates the previous pick.
                      _containerId = null;
                    }),
                    decoration: const InputDecoration(
                      labelText: 'Room (applies to all)',
                      isDense: true,
                    ),
                  ),
                if (containers.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    initialValue: _containerId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No container'),
                      ),
                      for (final c in containers)
                        DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                    ],
                    onChanged: (v) => setState(() => _containerId = v),
                    decoration: const InputDecoration(
                      labelText: 'Container (applies to all)',
                      isDense: true,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: OhSpacing.insetSm,
              itemCount: _entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return _ShelfEntryTile(
                  entry: entry,
                  onChanged: () => setState(() {}),
                  onShowCategorySheet: () =>
                      _showCategorySheet(entry, categories),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveAll,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_alt),
        label: const Text('Save'),
      ),
    );
  }
}

class _ShelfEntryTile extends StatelessWidget {
  final _ShelfEntry entry;
  final VoidCallback onChanged;
  final VoidCallback onShowCategorySheet;

  const _ShelfEntryTile({
    required this.entry,
    required this.onChanged,
    required this.onShowCategorySheet,
  });

  @override
  Widget build(BuildContext context) {
    final s = entry.suggestion;
    final categoryLabel = entry.hasCategoryOverride
        ? (entry.categoryIdOverride != null ? 'Category set' : 'Uncategorized')
        : (s.categoryName ?? 'Uncategorized');
    final brandModel = [
      if (s.brand != null) s.brand!,
      if (s.model != null) s.model!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: entry.accepted,
                onChanged: (v) {
                  entry.accepted = v ?? false;
                  onChanged();
                },
              ),
              Expanded(
                child: TextField(
                  controller: entry.nameController,
                  enabled: entry.accepted,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
              if (s.estimatedValue != null)
                Padding(
                  padding: const EdgeInsets.only(left: OhSpacing.xs),
                  child: Text(
                    '\$${s.estimatedValue!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
            ],
          ),
          if (brandModel.isNotEmpty || s.confidence != null)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                children: [
                  if (brandModel.isNotEmpty)
                    Flexible(
                      child: Text(
                        brandModel,
                        style: Theme.of(context).textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (s.confidence != null) ...[
                    const SizedBox(width: OhSpacing.xs),
                    Text(
                      '${(s.confidence! * 100).round()}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          GestureDetector(
            onTap: onShowCategorySheet,
            child: Padding(
              padding: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined, size: 16),
                  const SizedBox(width: OhSpacing.xs),
                  Text(
                    categoryLabel,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

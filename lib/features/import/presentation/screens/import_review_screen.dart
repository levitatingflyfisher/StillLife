import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../features/inventory/domain/entities/category.dart';
import '../../../../features/inventory/domain/entities/item.dart';
import '../../../../features/inventory/presentation/controllers/category_controller.dart';
import '../../../../features/locations/domain/entities/room.dart';
import '../../../../features/locations/presentation/controllers/location_controller.dart';
import '../../domain/import_review_item.dart';

const _uuid = Uuid();

/// Screen for reviewing and confirming imported items before saving to inventory.
class ImportReviewScreen extends ConsumerStatefulWidget {
  final List<ImportReviewItem> items;

  const ImportReviewScreen({super.key, required this.items});

  @override
  ConsumerState<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends ConsumerState<ImportReviewScreen> {
  late List<ImportReviewItem> _items;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  Future<void> _importAll() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    try {
      final seeder = ref.read(importFallbackSeederProvider);
      final (fallbackCategoryId, fallbackRoomId) = await seeder
          .ensureDefaults();
      final repo = ref.read(itemRepositoryProvider);
      final activeProfile = ref.read(activeProfileProvider).valueOrNull;

      int imported = 0;
      for (final item in _items) {
        if (!item.accepted) continue;

        final categoryId = item.categoryId ?? fallbackCategoryId;
        final roomId = item.roomId ?? fallbackRoomId;

        final entity = Item(
          id: _uuid.v4(),
          name: item.parsed.name,
          description: '',
          categoryId: categoryId,
          roomId: roomId,
          isInsured: false,
          purchasePrice: item.parsed.price,
          purchaseDate: item.parsed.purchaseDate,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          creatorProfileId: activeProfile?.id,
        );

        final result = await repo.createItem(entity);
        result.when(success: (_) => imported++, failure: (_) {});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $imported item${imported == 1 ? '' : 's'}'),
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showCategorySheet(ImportReviewItem item, List<Category> categories) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          ListTile(
            title: const Text('Uncategorized'),
            onTap: () {
              setState(() => item.categoryId = null);
              Navigator.of(ctx).pop();
            },
          ),
          ...categories.map((cat) {
            final isHint =
                item.parsed.categoryHint != null &&
                cat.name.toLowerCase() ==
                    item.parsed.categoryHint!.toLowerCase();
            return ListTile(
              title: Text(cat.name),
              trailing: isHint
                  ? const Icon(Icons.auto_awesome_outlined, size: 16)
                  : null,
              onTap: () {
                setState(() => item.categoryId = cat.id);
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
    final roomsAsync = ref.watch(allRoomsProvider);
    final rooms = roomsAsync.valueOrNull ?? <Room>[];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? <Category>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Import (${_items.length})'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Import All'),
            onPressed: _isImporting ? null : _importAll,
          ),
        ],
      ),
      body: ListView.separated(
        padding: OhSpacing.insetSm,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _ImportItemTile(
            item: item,
            rooms: rooms,
            onChanged: () => setState(() {}),
            onShowCategorySheet: () => _showCategorySheet(item, categories),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isImporting ? null : _importAll,
        icon: _isImporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_alt),
        label: const Text('Import'),
      ),
    );
  }
}

class _ImportItemTile extends StatelessWidget {
  final ImportReviewItem item;
  final List<Room> rooms;
  final VoidCallback onChanged;
  final VoidCallback onShowCategorySheet;

  const _ImportItemTile({
    required this.item,
    required this.rooms,
    required this.onChanged,
    required this.onShowCategorySheet,
  });

  @override
  Widget build(BuildContext context) {
    final categoryLabel = item.categoryId != null
        ? 'Category set'
        : (item.parsed.categoryHint ?? 'Uncategorized');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: item.accepted,
                onChanged: (v) {
                  item.accepted = v ?? false;
                  onChanged();
                },
              ),
              Expanded(
                child: Text(
                  item.parsed.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (item.parsed.price != null)
                Text(
                  '\$${item.parsed.price!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
          if (rooms.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: item.roomId,
              hint: const Text('Select room'),
              items: [
                for (final r in rooms)
                  DropdownMenuItem(value: r.id, child: Text(r.name)),
              ],
              onChanged: (v) {
                item.roomId = v;
                item.hasRoomOverride = v != null;
                onChanged();
              },
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                isDense: true,
              ),
            ),
          GestureDetector(
            onTap: onShowCategorySheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
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

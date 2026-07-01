import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../services/database/database.dart' show ReceiptsCompanion;
import '../../../../features/inventory/domain/entities/category.dart';
import '../../../../features/inventory/domain/entities/item.dart';
import '../../../../features/inventory/presentation/controllers/category_controller.dart';
import '../../../../features/locations/domain/entities/room.dart';
import '../../../../features/locations/presentation/controllers/location_controller.dart';
import '../../domain/import_review_args.dart';
import '../../domain/import_review_item.dart';
import '../../../../core/utils/money.dart';

const _uuid = Uuid();

/// Screen for reviewing and confirming imported items before saving to inventory.
class ImportReviewScreen extends ConsumerStatefulWidget {
  final List<ImportReviewItem> items;

  /// Receipt-level context when this import came from a receipt: engine
  /// label to show, receipt row to persist on save.
  final ImportReviewReceipt? receipt;

  const ImportReviewScreen({super.key, required this.items, this.receipt});

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
      final receiptId = await _persistReceipt();

      int imported = 0;
      int failed = 0;
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
          // Parsed receipt DTOs speak dollars; storage is cents.
          purchasePriceCents: centsFromDollarsOrNull(item.parsed.price),
          purchaseDate: item.parsed.purchaseDate,
          brand: item.parsed.brand,
          model: item.parsed.model,
          asin: item.parsed.asin,
          notes: item.parsed.notes,
          receiptId: receiptId,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          creatorProfileId: activeProfile?.id,
        );

        final result = await repo.createItem(entity);
        result.when(success: (_) => imported++, failure: (_) => failed++);
      }

      if (mounted) {
        final message = failed > 0
            ? 'Imported $imported of ${imported + failed} items — '
                  '$failed failed'
            : 'Imported $imported item${imported == 1 ? '' : 's'}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        context.pop();
      }
    } catch (e) {
      // A thrown import (seeder/receipt insert) must surface — the
      // screen stays open so the user can retry.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  /// For a receipt-sourced import with at least one accepted item, inserts
  /// the ONE Receipts row (photo, OCR text, store, date, total) that every
  /// accepted item will link to via `Items.receiptId`. `Receipts.itemId`
  /// stays null — one receipt covers many items, so the link lives on
  /// Items. Returns null for non-receipt imports.
  Future<String?> _persistReceipt() async {
    final receipt = widget.receipt;
    if (receipt == null) return null;
    if (!_items.any((i) => i.accepted)) return null;

    final receiptId = _uuid.v4();
    await ref.read(databaseProvider).receiptDao.insertReceipt(
          ReceiptsCompanion.insert(
            id: receiptId,
            photoPath: '',
            photoBytes: Value(receipt.imageBytes),
            storeName: Value(receipt.storeName),
            purchaseDate: Value(receipt.purchaseDate),
            totalAmountCents: Value(centsFromDollarsOrNull(receipt.totalAmount)),
            ocrText: Value(receipt.ocrText),
            createdAt: DateTime.now(),
          ),
        );
    return receiptId;
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
      body: Column(
        children: [
          if (widget.receipt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: OhSpacing.xs),
                  Expanded(
                    child: Text(
                      widget.receipt!.engineLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: OhSpacing.insetSm,
              itemCount: _items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _ImportItemTile(
                  item: item,
                  rooms: rooms,
                  onChanged: () => setState(() {}),
                  onShowCategorySheet: () =>
                      _showCategorySheet(item, categories),
                );
              },
            ),
          ),
        ],
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

    // Everything that will be persisted must be visible to the reviewer:
    // brand/model are LLM-written on the receipt path, and silently
    // saving fields the user never saw defeats the review step.
    final brandModel = [
      if ((item.parsed.brand ?? '').isNotEmpty) item.parsed.brand!,
      if ((item.parsed.model ?? '').isNotEmpty) item.parsed.model!,
    ].join(' · ');

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
          if (brandModel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                brandModel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
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

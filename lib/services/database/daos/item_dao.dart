import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'item_dao.g.dart';

@DriftAccessor(
  tables: [
    Items,
    Categories,
    Rooms,
    Photos,
    ItemTags,
    Tags,
    Receipts,
    Appraisals,
  ],
)
class ItemDao extends DatabaseAccessor<AppDatabase> with _$ItemDaoMixin {
  ItemDao(super.db);

  /// Watch all items, optionally filtered.
  Stream<List<Item>> watchAllItems({
    String? roomId,
    String? categoryId,
    String? containerId,
    String? condition,
    double? minValue,
    double? maxValue,
    String? priceField,
    DateTime? addedAfter,
    DateTime? addedBefore,
    bool? hasPhoto,
    bool? hasReceipt,
    bool? hasBarcode,
    String? profileId,
    String? sortBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) {
    final query = select(items)..where((t) => t.isDeleted.equals(false));

    if (roomId != null) {
      query.where((t) => t.roomId.equals(roomId));
    }
    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    if (containerId != null) {
      query.where((t) => t.containerId.equals(containerId));
    }
    if (condition != null) {
      query.where((t) => t.condition.equals(condition));
    }
    // Apply min/max to the selected price field (defaults to currentValue).
    if (minValue != null) {
      switch (priceField) {
        case 'purchasePrice':
          query.where((t) => t.purchasePrice.isBiggerOrEqualValue(minValue));
        case 'replacementCost':
          query.where((t) => t.replacementCost.isBiggerOrEqualValue(minValue));
        default:
          query.where((t) => t.currentValue.isBiggerOrEqualValue(minValue));
      }
    }
    if (maxValue != null) {
      switch (priceField) {
        case 'purchasePrice':
          query.where((t) => t.purchasePrice.isSmallerOrEqualValue(maxValue));
        case 'replacementCost':
          query.where((t) => t.replacementCost.isSmallerOrEqualValue(maxValue));
        default:
          query.where((t) => t.currentValue.isSmallerOrEqualValue(maxValue));
      }
    }
    if (addedAfter != null) {
      query.where((t) => t.createdAt.isBiggerThanValue(addedAfter));
    }
    if (addedBefore != null) {
      query.where((t) => t.createdAt.isSmallerThanValue(addedBefore));
    }
    if (hasPhoto == true) {
      query.where(
        (t) => const CustomExpression<bool>(
          'EXISTS (SELECT 1 FROM photos WHERE photos.item_id = items.id AND photos.is_deleted = 0)',
        ),
      );
    }
    if (hasReceipt == true) {
      query.where(
        (t) => const CustomExpression<bool>(
          'EXISTS (SELECT 1 FROM receipts WHERE receipts.item_id = items.id AND receipts.is_deleted = 0)',
        ),
      );
    }
    if (hasBarcode == true) {
      query.where((t) => t.barcode.isNotNull() & t.barcode.isNotValue(''));
    }
    if (profileId != null) {
      query.where(
        (t) =>
            t.creatorProfileId.equals(profileId) |
            t.ownerProfileId.equals(profileId),
      );
    }

    // Sorting
    final orderMode = ascending ? OrderingMode.asc : OrderingMode.desc;
    switch (sortBy) {
      case 'currentValue':
        query.orderBy([
          (t) => OrderingTerm(expression: t.currentValue, mode: orderMode),
        ]);
      case 'replacementCost':
        query.orderBy([
          (t) => OrderingTerm(expression: t.replacementCost, mode: orderMode),
        ]);
      case 'createdAt':
        query.orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: orderMode),
        ]);
      case 'purchaseDate':
        query.orderBy([
          (t) => OrderingTerm(expression: t.purchaseDate, mode: orderMode),
        ]);
      default:
        query.orderBy([
          (t) => OrderingTerm(expression: t.name, mode: orderMode),
        ]);
    }

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    return query.watch();
  }

  /// Get a single item by ID (excludes soft-deleted).
  Future<Item?> getItemById(String id) {
    return (select(items)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Find the first item whose barcode matches (null if not in inventory).
  Future<Item?> getItemByBarcode(String barcode) {
    return (select(items)
          ..where((t) => t.barcode.equals(barcode))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Watch all items where quantity is tracked AND at or below the low-stock threshold.
  ///
  /// Pure SQL: column-to-column comparison via [Expression.isSmallerOrEqual]
  /// keeps the filter on the DB side so we don't materialise the whole
  /// quantity-tracked inventory just to throw most of it away.
  Stream<List<Item>> watchLowStockItems() {
    return (select(items)
          ..where(
            (t) =>
                t.isDeleted.equals(false) &
                t.quantity.isNotNull() &
                t.lowStockThreshold.isNotNull() &
                t.quantity.isSmallerOrEqual(t.lowStockThreshold),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Decrement this item's quantity by 1, floored at 0.
  /// No-op when the item has no quantity set. Stamps [crdt] if provided.
  ///
  /// Wrapped in a transaction with a re-read so concurrent double-taps
  /// (e.g. a user spamming the decrement button) cannot read-modify-write
  /// the same value twice and effectively skip a decrement.
  Future<void> decrementQuantity(String id, {CrdtManager? crdt}) async {
    await db.transaction(() async {
      // Re-read inside the transaction so two interleaved decrements
      // each see the other's write.
      final row =
          await (select(items)
                ..where((t) => t.id.equals(id))
                ..where((t) => t.isDeleted.equals(false)))
              .getSingleOrNull();
      if (row == null || row.quantity == null) return;
      final newQty = (row.quantity! - 1).clamp(0.0, double.infinity);
      var entry = ItemsCompanion(
        id: Value(id),
        quantity: Value(newQty),
        modifiedAt: Value(DateTime.now()),
      );
      if (crdt != null) {
        final nodeId = await crdt.getNodeId();
        final hlc = await crdt.nextHlc();
        entry = entry.copyWith(
          nodeId: Value(nodeId),
          hlc: Value(hlc.toString()),
        );
      }
      await (update(items)..where((t) => t.id.equals(id))).write(entry);
    });
  }

  /// Insert a new item. If [crdt] is provided, stamps nodeId/hlc.
  Future<void> insertItem(ItemsCompanion entry, {CrdtManager? crdt}) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await into(items).insert(entry);
  }

  /// Update an existing item. If [crdt] is provided, stamps nodeId/hlc.
  Future<bool> updateItem(ItemsCompanion entry, {CrdtManager? crdt}) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return (update(items)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Soft-delete an item and its associated photos and appraisals
  /// (itemTags are hard-deleted).
  ///
  /// When [crdt] is provided, stamps `nodeId`/`hlc` on the item tombstone and
  /// each related photo/appraisal tombstone so the CRDT merge engine can
  /// propagate them to peers.
  ///
  /// Wrapped in a single DB transaction so partial failures cannot leave
  /// orphaned photos/appraisals pointing at a "live" item or vice versa.
  Future<void> deleteItem(String id, {CrdtManager? crdt}) async {
    await db.transaction(() async {
      final now = DateTime.now();
      // Soft-delete associated photos (keeps tombstones for sync).
      // Each photo row gets its own CRDT stamp so peers can merge the tombstones.
      final photoRows = await (select(
        photos,
      )..where((t) => t.itemId.equals(id))).get();
      for (final photo in photoRows) {
        var entry = PhotosCompanion(
          id: Value(photo.id),
          isDeleted: const Value(true),
          modifiedAt: Value(now),
        );
        if (crdt != null) {
          final nodeId = await crdt.getNodeId();
          final hlc = await crdt.nextHlc();
          entry = entry.copyWith(
            nodeId: Value(nodeId),
            hlc: Value(hlc.toString()),
          );
        }
        await (update(
          photos,
        )..where((t) => t.id.equals(photo.id))).write(entry);
      }
      // Soft-delete associated appraisals (cache rows tied to this item).
      // Without this, the per-item appraisal cache survives item deletion and
      // can resurface stale market values if the item id is reused.
      final appraisalRows = await (select(
        appraisals,
      )..where((t) => t.itemId.equals(id))).get();
      for (final appraisal in appraisalRows) {
        var entry = AppraisalsCompanion(
          id: Value(appraisal.id),
          isDeleted: const Value(true),
        );
        if (crdt != null) {
          final nodeId = await crdt.getNodeId();
          final hlc = await crdt.nextHlc();
          entry = entry.copyWith(
            nodeId: Value(nodeId),
            hlc: Value(hlc.toString()),
          );
        }
        await (update(
          appraisals,
        )..where((t) => t.id.equals(appraisal.id))).write(entry);
      }
      // Hard-delete junction rows (not individually synced).
      await (delete(itemTags)..where((t) => t.itemId.equals(id))).go();
      // Soft-delete the item itself.
      var itemEntry = ItemsCompanion(
        id: Value(id),
        isDeleted: const Value(true),
        modifiedAt: Value(now),
      );
      if (crdt != null) {
        final nodeId = await crdt.getNodeId();
        final hlc = await crdt.nextHlc();
        itemEntry = itemEntry.copyWith(
          nodeId: Value(nodeId),
          hlc: Value(hlc.toString()),
        );
      }
      await (update(items)..where((t) => t.id.equals(id))).write(itemEntry);
    });
  }

  /// Bulk soft-delete items and their related data.
  /// Each item gets its own CRDT stamp when [crdt] is provided.
  Future<void> deleteItems(List<String> ids, {CrdtManager? crdt}) async {
    for (final id in ids) {
      await deleteItem(id, crdt: crdt);
    }
  }

  /// Bulk move items to a new room.
  /// Each item gets its own CRDT stamp when [crdt] is provided so the move
  /// propagates row-by-row through the sync engine.
  Future<void> moveItemsToRoom(
    List<String> itemIds,
    String newRoomId, {
    CrdtManager? crdt,
  }) async {
    final now = DateTime.now();
    for (final id in itemIds) {
      var entry = ItemsCompanion(
        id: Value(id),
        roomId: Value(newRoomId),
        modifiedAt: Value(now),
      );
      if (crdt != null) {
        final nodeId = await crdt.getNodeId();
        final hlc = await crdt.nextHlc();
        entry = entry.copyWith(
          nodeId: Value(nodeId),
          hlc: Value(hlc.toString()),
        );
      }
      await (update(items)..where((t) => t.id.equals(id))).write(entry);
    }
  }

  /// Count items matching criteria (excludes soft-deleted).
  Future<int> countItems({String? roomId, String? categoryId}) async {
    final query = items.id.count();
    final sel = selectOnly(items)
      ..addColumns([query])
      ..where(items.isDeleted.equals(false));
    if (roomId != null) {
      sel.where(items.roomId.equals(roomId));
    }
    if (categoryId != null) {
      sel.where(items.categoryId.equals(categoryId));
    }
    final result = await sel.getSingle();
    return result.read(query) ?? 0;
  }

  /// Full-text search using FTS5 — returns a reactive stream (excludes soft-deleted).
  Stream<List<Item>> searchItems(String searchQuery) {
    final ftsQuery = searchQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '$w*')
        .join(' ');

    if (ftsQuery.isEmpty) return const Stream.empty();

    return customSelect(
      'SELECT items.* FROM items INNER JOIN items_fts ON items.rowid = items_fts.rowid'
      ' WHERE items_fts MATCH ? AND items.is_deleted = 0',
      variables: [Variable.withString(ftsQuery)],
      readsFrom: {items},
    ).watch().map((rows) => rows.map((row) => items.map(row.data)).toList());
  }

  /// Get total value of all items (excludes soft-deleted).
  Future<double> getTotalValue({String? roomId, String? categoryId}) async {
    final sumExpr = items.currentValue.sum();
    final query = selectOnly(items)
      ..addColumns([sumExpr])
      ..where(items.isDeleted.equals(false));
    if (roomId != null) {
      query.where(items.roomId.equals(roomId));
    }
    if (categoryId != null) {
      query.where(items.categoryId.equals(categoryId));
    }
    final result = await query.getSingle();
    return result.read(sumExpr) ?? 0.0;
  }

  /// Get total replacement cost (excludes soft-deleted).
  Future<double> getTotalReplacementCost({
    String? roomId,
    String? categoryId,
  }) async {
    final sumExpr = items.replacementCost.sum();
    final query = selectOnly(items)
      ..addColumns([sumExpr])
      ..where(items.isDeleted.equals(false));
    if (roomId != null) {
      query.where(items.roomId.equals(roomId));
    }
    if (categoryId != null) {
      query.where(items.categoryId.equals(categoryId));
    }
    final result = await query.getSingle();
    return result.read(sumExpr) ?? 0.0;
  }

  /// Get total acquisition cost (excludes soft-deleted).
  Future<double> getTotalAcquisitionCost({String? roomId}) async {
    final sumExpr = items.purchasePrice.sum();
    final query = selectOnly(items)
      ..addColumns([sumExpr])
      ..where(items.isDeleted.equals(false));
    if (roomId != null) {
      query.where(items.roomId.equals(roomId));
    }
    final result = await query.getSingle();
    return result.read(sumExpr) ?? 0.0;
  }

  /// Get value breakdown by room (excludes soft-deleted).
  Future<Map<String, double>> getValueByRoom() async {
    final sumExpr = items.currentValue.sum();
    final query = selectOnly(items)
      ..addColumns([items.roomId, sumExpr])
      ..where(items.isDeleted.equals(false))
      ..groupBy([items.roomId]);
    final results = await query.get();
    return {
      for (final row in results)
        row.read(items.roomId)!: row.read(sumExpr) ?? 0.0,
    };
  }

  /// Get items with warranty expiring within [withinDays] days (excludes soft-deleted).
  Future<List<Item>> getWarrantyExpiringSoon({required int withinDays}) async {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));
    return (select(items)
          ..where(
            (t) =>
                t.isDeleted.equals(false) &
                t.warrantyExpiration.isNotNull() &
                t.warrantyExpiration.isSmallerOrEqualValue(cutoff),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.warrantyExpiration)]))
        .get();
  }

  /// Get value breakdown by category (excludes soft-deleted).
  Future<Map<String, double>> getValueByCategory() async {
    final sumExpr = items.currentValue.sum();
    final query = selectOnly(items)
      ..addColumns([items.categoryId, sumExpr])
      ..where(items.isDeleted.equals(false))
      ..groupBy([items.categoryId]);
    final results = await query.get();
    return {
      for (final row in results)
        row.read(items.categoryId)!: row.read(sumExpr) ?? 0.0,
    };
  }
}

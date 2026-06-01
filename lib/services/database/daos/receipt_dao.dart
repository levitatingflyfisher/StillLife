import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'receipt_dao.g.dart';

@DriftAccessor(tables: [Receipts])
class ReceiptDao extends DatabaseAccessor<AppDatabase> with _$ReceiptDaoMixin {
  ReceiptDao(super.db);

  /// Watch all receipts for a given item, ordered by creation date descending.
  Stream<List<Receipt>> watchReceiptsForItem(String itemId) {
    return (select(receipts)
          ..where((t) => t.itemId.equals(itemId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get a single receipt by ID (excludes soft-deleted).
  Future<Receipt?> getReceipt(String id) {
    return (select(receipts)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Insert a new receipt. If [crdt] is provided, stamps nodeId/hlc.
  Future<void> insertReceipt(
    ReceiptsCompanion receipt, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      receipt = receipt.copyWith(
        nodeId: Value(nodeId),
        hlc: Value(hlc.toString()),
      );
    }
    await into(receipts).insert(receipt);
  }

  /// Soft-delete a receipt by ID.
  ///
  /// When [crdt] is provided, stamps `nodeId`/`hlc` on the tombstone so the
  /// CRDT merge engine can propagate it to peers.
  Future<void> deleteReceipt(String id, {CrdtManager? crdt}) async {
    var entry = ReceiptsCompanion(id: Value(id), isDeleted: const Value(true));
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await (update(receipts)..where((t) => t.id.equals(id))).write(entry);
  }
}

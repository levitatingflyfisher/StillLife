import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'price_history_dao.g.dart';

@DriftAccessor(tables: [PriceHistoryEntries])
class PriceHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$PriceHistoryDaoMixin {
  PriceHistoryDao(super.db);

  /// Watch price history for an item, ordered by recordedAt descending.
  Stream<List<PriceHistoryEntry>> watchPriceHistory(String itemId) {
    return (select(priceHistoryEntries)
          ..where((t) => t.itemId.equals(itemId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .watch();
  }

  /// Insert a new price history entry. If [crdt] is provided, stamps nodeId/hlc.
  Future<void> insertPriceEntry(
    PriceHistoryEntriesCompanion entry, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await into(priceHistoryEntries).insert(entry);
  }

  /// Get the most recent price entry for an item.
  Future<PriceHistoryEntry?> getLatestPrice(String itemId) {
    return (select(priceHistoryEntries)
          ..where((t) => t.itemId.equals(itemId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}

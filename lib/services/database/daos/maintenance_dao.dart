import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'maintenance_dao.g.dart';

@DriftAccessor(tables: [MaintenanceLogs])
class MaintenanceDao extends DatabaseAccessor<AppDatabase>
    with _$MaintenanceDaoMixin {
  MaintenanceDao(super.db);

  Future<int> insertLog(
    MaintenanceLogsCompanion entry, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return into(maintenanceLogs).insert(entry);
  }

  Future<bool> updateLog(
    MaintenanceLogsCompanion entry, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return (update(maintenanceLogs)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Soft-deletes a maintenance log.
  /// Returns the number of rows affected (1 if the row existed, 0 otherwise).
  ///
  /// When [crdt] is provided, stamps `nodeId`/`hlc` on the tombstone so the
  /// CRDT merge engine can propagate it to peers.
  Future<int> deleteLog(String id, {CrdtManager? crdt}) async {
    var entry = MaintenanceLogsCompanion(
      id: Value(id),
      isDeleted: const Value(true),
      modifiedAt: Value(DateTime.now()),
    );
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return (update(
      maintenanceLogs,
    )..where((t) => t.id.equals(id) & t.isDeleted.equals(false))).write(entry);
  }

  Future<MaintenanceLog?> getById(String id) =>
      (select(maintenanceLogs)
            ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
          .getSingleOrNull();

  Stream<List<MaintenanceLog>> watchAll() =>
      (select(maintenanceLogs)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.performedAt)]))
          .watch();

  Stream<List<MaintenanceLog>> watchByItem(String itemId) =>
      (select(maintenanceLogs)
            ..where((t) => t.itemId.equals(itemId) & t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.performedAt)]))
          .watch();

  Future<List<MaintenanceLog>> getUpcoming() {
    final now = DateTime.now();
    return (select(maintenanceLogs)
          ..where(
            (t) =>
                t.isDeleted.equals(false) &
                t.nextDueAt.isNotNull() &
                t.nextDueAt.isBiggerOrEqualValue(now),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.nextDueAt)]))
        .get();
  }
}

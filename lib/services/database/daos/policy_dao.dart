import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'policy_dao.g.dart';

@DriftAccessor(tables: [Policies])
class PolicyDao extends DatabaseAccessor<AppDatabase> with _$PolicyDaoMixin {
  PolicyDao(super.db);

  Stream<List<Policy>> watchAll() =>
      (select(policies)..where((t) => t.isDeleted.equals(false))).watch();

  Future<List<Policy>> getAll() =>
      (select(policies)..where((t) => t.isDeleted.equals(false))).get();

  Future<Policy?> getById(String id) =>
      (select(policies)
            ..where((t) => t.id.equals(id))
            ..where((t) => t.isDeleted.equals(false)))
          .getSingleOrNull();

  Future<List<Policy>> getByPropertyId(String propertyId) =>
      (select(policies)..where(
            (t) => t.propertyId.equals(propertyId) & t.isDeleted.equals(false),
          ))
          .get();

  Future<int> insertPolicy(PoliciesCompanion entry, {CrdtManager? crdt}) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return into(policies).insert(entry);
  }

  Future<bool> updatePolicy(
    PoliciesCompanion entry, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return (update(policies)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Soft-delete a policy.
  /// Returns the number of rows affected (1 if the policy existed and was
  /// not already deleted, 0 otherwise).
  ///
  /// When [crdt] is provided, stamps `nodeId`/`hlc` on the tombstone so the
  /// CRDT merge engine can propagate it to peers.
  Future<int> deletePolicy(String id, {CrdtManager? crdt}) async {
    var entry = PoliciesCompanion(
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
      policies,
    )..where((t) => t.id.equals(id) & t.isDeleted.equals(false))).write(entry);
  }
}

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'appraisal_dao.g.dart';

/// DAO for appraisals (market-value estimates cached 30 days per
/// `(itemModelKey, mode, countryCode)`).
@DriftAccessor(tables: [Appraisals])
class AppraisalDao extends DatabaseAccessor<AppDatabase>
    with _$AppraisalDaoMixin {
  AppraisalDao(super.db);

  Stream<List<Appraisal>> watchForItem(String itemId) {
    return (select(appraisals)
          ..where((t) => t.itemId.equals(itemId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.queriedAt)]))
        .watch();
  }

  Future<Appraisal?> getLatestByItemAndMode(String itemId, String mode) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (select(appraisals)
          ..where(
            (t) =>
                t.itemId.equals(itemId) &
                t.mode.equals(mode) &
                t.isDeleted.equals(false) &
                t.expiresAt.isBiggerThanValue(now),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.queriedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Appraisal?> getLatestByCacheKey(
    String itemModelKey,
    String mode,
    String countryCode,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (select(appraisals)
          ..where(
            (t) =>
                t.itemModelKey.equals(itemModelKey) &
                t.mode.equals(mode) &
                t.countryCode.equals(countryCode) &
                t.isDeleted.equals(false) &
                t.expiresAt.isBiggerThanValue(now),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.queriedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> insertAppraisal(
    AppraisalsCompanion row, {
    CrdtManager? crdt,
  }) async {
    var stamped = row;
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      stamped = stamped.copyWith(
        nodeId: Value(nodeId),
        hlc: Value(hlc.toString()),
      );
    }
    await into(appraisals).insert(stamped);
  }

  Future<int> softDelete(String id, {CrdtManager? crdt}) async {
    var companion = const AppraisalsCompanion(isDeleted: Value(true));
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      companion = companion.copyWith(
        nodeId: Value(nodeId),
        hlc: Value(hlc.toString()),
      );
    }
    return (update(appraisals)..where((t) => t.id.equals(id))).write(companion);
  }

  /// Soft-deletes appraisals whose [expiresAt] is in the past.
  ///
  /// Hard-deleting expired rows would break LWW sync: a peer that hasn't
  /// seen the deletion can resurrect the row on the next merge. Soft-delete
  /// stamps a CRDT tombstone instead so peers converge.
  ///
  /// Returns the number of rows updated.
  Future<int> softDeleteExpired({CrdtManager? crdt}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final stale =
        await (select(appraisals)..where(
              (t) =>
                  t.expiresAt.isSmallerThanValue(now) &
                  t.isDeleted.equals(false),
            ))
            .get();
    if (stale.isEmpty) return 0;

    var count = 0;
    await db.transaction(() async {
      for (final row in stale) {
        var entry = AppraisalsCompanion(
          id: Value(row.id),
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
        final updated = await (update(
          appraisals,
        )..where((t) => t.id.equals(row.id))).write(entry);
        count += updated;
      }
    });
    return count;
  }

  /// Hard-deletes appraisal rows that are already soft-deleted AND whose
  /// [expiresAt] is older than `now - grace`. Used to keep the appraisal
  /// cache from growing unbounded once peers have had a chance to see the
  /// tombstone.
  ///
  /// Default grace window is 30 days.
  Future<int> vacuumExpired({Duration grace = const Duration(days: 30)}) {
    final cutoff = DateTime.now().subtract(grace).millisecondsSinceEpoch;
    return (delete(appraisals)..where(
          (t) =>
              t.isDeleted.equals(true) & t.expiresAt.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  /// Deprecated: use [softDeleteExpired] instead. Hard-deleting expired
  /// rows breaks CRDT convergence.
  @Deprecated('Use softDeleteExpired() — hard delete breaks LWW sync.')
  Future<int> pruneExpired({CrdtManager? crdt}) =>
      softDeleteExpired(crdt: crdt);
}

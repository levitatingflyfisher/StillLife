import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'loan_dao.g.dart';

@DriftAccessor(tables: [Loans, Items])
class LoanDao extends DatabaseAccessor<AppDatabase> with _$LoanDaoMixin {
  LoanDao(super.db);

  /// Returns all non-deleted loans for an item, with item name from JOIN.
  Stream<List<(Loan, String)>> watchByItem(String itemId) {
    final query =
        (select(loans)
              ..where(
                (l) => l.itemId.equals(itemId) & l.isDeleted.equals(false),
              )
              ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
            .join([leftOuterJoin(items, items.id.equalsExp(loans.itemId))]);
    return query.watch().map(
      (rows) => rows.map((row) {
        final loan = row.readTable(loans);
        final itemName = row.readTableOrNull(items)?.name ?? '';
        return (loan, itemName);
      }).toList(),
    );
  }

  /// Returns all active (unreturned) non-deleted loans whose item is also
  /// not soft-deleted, with item name from JOIN.
  ///
  /// Uses an INNER join so loans pointing at deleted items are filtered
  /// server-side rather than appearing as `(loan, '')` placeholders.
  Stream<List<(Loan, String)>> watchActiveLoans() {
    final query =
        (select(loans)
              ..where((l) => l.returnedAt.isNull() & l.isDeleted.equals(false))
              ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
            .join([
              innerJoin(
                items,
                items.id.equalsExp(loans.itemId) &
                    items.isDeleted.equals(false),
              ),
            ]);
    return query.watch().map(
      (rows) => rows.map((row) {
        final loan = row.readTable(loans);
        final itemName = row.readTable(items).name;
        return (loan, itemName);
      }).toList(),
    );
  }

  /// Returns the set of item IDs that have an active (unreturned) loan
  /// whose item is also not soft-deleted.
  Stream<Set<String>> watchActiveLoanItemIds() {
    final query =
        (select(loans)
              ..where((l) => l.returnedAt.isNull() & l.isDeleted.equals(false)))
            .join([
              innerJoin(
                items,
                items.id.equalsExp(loans.itemId) &
                    items.isDeleted.equals(false),
              ),
            ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(loans).itemId).toSet(),
    );
  }

  Future<void> insertLoan(LoansCompanion companion, {CrdtManager? crdt}) async {
    final stamped = crdt != null
        ? companion.copyWith(
            nodeId: Value(await crdt.getNodeId()),
            hlc: Value((await crdt.nextHlc()).toString()),
          )
        : companion;
    await into(loans).insert(stamped);
  }

  Future<void> updateLoan(LoansCompanion companion, {CrdtManager? crdt}) async {
    final stamped = crdt != null
        ? companion.copyWith(
            nodeId: Value(await crdt.getNodeId()),
            hlc: Value((await crdt.nextHlc()).toString()),
            modifiedAt: Value(DateTime.now()),
          )
        : companion.copyWith(modifiedAt: Value(DateTime.now()));
    await (update(
      loans,
    )..where((l) => l.id.equals(stamped.id.value))).write(stamped);
  }

  /// Soft-deletes a loan by setting [isDeleted]=true.
  ///
  /// **IMPORTANT:** Always pass [crdt] in production to stamp [nodeId]/[hlc]
  /// so the CRDT merge engine can propagate this tombstone to peers over LAN sync.
  /// Omitting [crdt] (tests only) skips CRDT stamping and the tombstone won't sync.
  Future<void> softDelete(String id, {CrdtManager? crdt}) async {
    final companion = crdt != null
        ? LoansCompanion(
            id: Value(id),
            isDeleted: const Value(true),
            modifiedAt: Value(DateTime.now()),
            nodeId: Value(await crdt.getNodeId()),
            hlc: Value((await crdt.nextHlc()).toString()),
          )
        : LoansCompanion(
            id: Value(id),
            isDeleted: const Value(true),
            modifiedAt: Value(DateTime.now()),
          );
    await (update(loans)..where((l) => l.id.equals(id))).write(companion);
  }
}

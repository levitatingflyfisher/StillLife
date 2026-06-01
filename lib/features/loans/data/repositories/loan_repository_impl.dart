import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db_pkg;
import '../../domain/entities/loan.dart';
import '../../domain/repositories/loan_repository.dart';

const _uuid = Uuid();

class LoanRepositoryImpl implements LoanRepository {
  final db_pkg.AppDatabase _db;
  LoanRepositoryImpl(this._db);

  @override
  Stream<List<Loan>> watchByItem(String itemId) => _db.loanDao
      .watchByItem(itemId)
      .map((pairs) => pairs.map((p) => _map(p.$1, p.$2)).toList());

  @override
  Stream<List<Loan>> watchActiveLoans() => _db.loanDao.watchActiveLoans().map(
    (pairs) => pairs.map((p) => _map(p.$1, p.$2)).toList(),
  );

  @override
  Future<Result<Loan>> createLoan(Loan loan) async {
    try {
      // Guard: one active loan per item
      final existing = await _db.loanDao.watchByItem(loan.itemId).first;
      final hasActiveLoan = existing.any((p) => p.$1.returnedAt == null);
      if (hasActiveLoan) {
        return const Err(DatabaseFailure('Item already on loan'));
      }

      final id = loan.id.isEmpty ? _uuid.v4() : loan.id;
      final now = DateTime.now();
      await _db.loanDao.insertLoan(
        db_pkg.LoansCompanion.insert(
          id: id,
          itemId: loan.itemId,
          borrowerName: loan.borrowerName,
          expectedReturnDate: Value(loan.expectedReturnDate),
          notes: Value(loan.notes),
          createdAt: now,
          modifiedAt: now,
        ),
      );
      final pairs = await _db.loanDao.watchByItem(loan.itemId).first;
      final pair = pairs.firstWhere((p) => p.$1.id == id);
      return Success(_map(pair.$1, pair.$2));
    } catch (e) {
      return Err(DatabaseFailure('Failed to create loan: $e'));
    }
  }

  @override
  Future<Result<Loan>> editLoan(Loan loan) async {
    try {
      await _db.loanDao.updateLoan(
        db_pkg.LoansCompanion(
          id: Value(loan.id),
          borrowerName: Value(loan.borrowerName),
          expectedReturnDate: Value(loan.expectedReturnDate),
          notes: Value(loan.notes),
          modifiedAt: Value(DateTime.now()),
        ),
      );
      final pairs = await _db.loanDao.watchByItem(loan.itemId).first;
      final pair = pairs.firstWhere((p) => p.$1.id == loan.id);
      return Success(_map(pair.$1, pair.$2));
    } catch (e) {
      return Err(DatabaseFailure('Failed to edit loan: $e'));
    }
  }

  @override
  Future<Result<void>> markReturned(String id) async {
    try {
      await _db.loanDao.updateLoan(
        db_pkg.LoansCompanion(id: Value(id), returnedAt: Value(DateTime.now())),
      );
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to mark returned: $e'));
    }
  }

  @override
  Future<Result<void>> deleteLoan(String id) async {
    try {
      await _db.loanDao.softDelete(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete loan: $e'));
    }
  }

  Loan _map(db_pkg.Loan row, String itemName) => Loan(
    id: row.id,
    itemId: row.itemId,
    itemName: itemName,
    borrowerName: row.borrowerName,
    expectedReturnDate: row.expectedReturnDate,
    notes: row.notes,
    returnedAt: row.returnedAt,
    createdAt: row.createdAt,
    modifiedAt: row.modifiedAt,
  );
}

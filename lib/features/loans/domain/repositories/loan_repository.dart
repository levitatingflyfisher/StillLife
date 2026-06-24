import '../../../../core/errors/result.dart';
import '../entities/loan.dart';

abstract class LoanRepository {
  Stream<List<Loan>> watchByItem(String itemId);
  Stream<List<Loan>> watchActiveLoans();
  Future<Result<Loan>> createLoan(Loan loan);
  Future<Result<Loan>> editLoan(
    Loan loan,
  ); // named editLoan — avoids AsyncNotifier.update() collision
  Future<Result<void>> markReturned(String id);
  Future<Result<void>> deleteLoan(String id);
}

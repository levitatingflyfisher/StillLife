import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/notification_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/loan.dart';
import '../../domain/repositories/loan_repository.dart';

final activeLoansProvider = StreamProvider<List<Loan>>(
  (ref) => ref.watch(loanRepositoryProvider).watchActiveLoans(),
);

final itemLoansProvider = StreamProvider.family<List<Loan>, String>(
  (ref, itemId) => ref.watch(loanRepositoryProvider).watchByItem(itemId),
);

/// Set of item IDs with an active (unreturned) loan.
/// Used by ItemListTile to show the "On Loan" badge without per-tile streams.
final activeLoanedItemIdsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(databaseProvider).loanDao.watchActiveLoanItemIds(),
);

final loanControllerProvider = AsyncNotifierProvider<LoanController, void>(
  LoanController.new,
);

class LoanController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  LoanRepository get _repo => ref.read(loanRepositoryProvider);

  Future<void> lend(Loan loan) async {
    state = const AsyncLoading();
    final result = await _repo.createLoan(loan);
    result.when(
      success: (_) => state = const AsyncData(null),
      failure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }

  // Named editLoan — avoids collision with AsyncNotifier.update()
  Future<void> editLoan(Loan loan) async {
    state = const AsyncLoading();
    final result = await _repo.editLoan(loan);
    result.when(
      success: (_) => state = const AsyncData(null),
      failure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }

  Future<void> markReturned(String id) async {
    state = const AsyncLoading();
    final result = await _repo.markReturned(id);
    result.when(
      success: (_) {
        unawaited(ref.read(notificationServiceProvider).cancelLoanReminder(id));
        state = const AsyncData(null);
      },
      failure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    final result = await _repo.deleteLoan(id);
    result.when(
      success: (_) {
        unawaited(ref.read(notificationServiceProvider).cancelLoanReminder(id));
        state = const AsyncData(null);
      },
      failure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }
}

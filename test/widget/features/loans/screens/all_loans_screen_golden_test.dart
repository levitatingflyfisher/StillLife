import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/loans/domain/entities/loan.dart';
import 'package:still_life/features/loans/presentation/controllers/loan_controller.dart';
import 'package:still_life/features/loans/presentation/screens/all_loans_screen.dart';

import '../../../../visual/visual_golden_helper.dart';

Loan _loan({
  String id = 'l1',
  String itemName = 'Camera',
  String borrower = 'Alice',
  DateTime? expectedReturnDate,
}) => Loan(
  id: id,
  itemId: 'i1',
  itemName: itemName,
  borrowerName: borrower,
  expectedReturnDate: expectedReturnDate,
  createdAt: DateTime(2025),
  modifiedAt: DateTime(2025),
);

class _FakeCtrl extends LoanController {
  @override
  Future<void> build() async {}
  @override
  Future<void> markReturned(String id) async {}
}

/// Mirrors all_loans_screen_test.dart's ProviderScope/mock setup exactly, but
/// renders the screen itself as `home` so the helper supplies the MaterialApp.
Widget _screen(List<Loan> loans) => ProviderScope(
  overrides: [
    activeLoansProvider.overrideWith((ref) => Stream.value(loans)),
    loanControllerProvider.overrideWith(() => _FakeCtrl()),
  ],
  child: const AllLoansScreen(),
);

void main() {
  testWidgets('AllLoansScreen empty golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'all_loans_screen_empty',
      home: _screen(const <Loan>[]),
      textScales: const <double>[1.0, 3.0],
    );
  });

  testWidgets('AllLoansScreen single active golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'all_loans_screen_active',
      home: _screen([
        _loan(expectedReturnDate: DateTime.now().add(const Duration(days: 10))),
      ]),
      textScales: const <double>[1.0, 3.0],
    );
  });

  testWidgets('AllLoansScreen grouped (overdue/due-soon/upcoming) golden sweep', (
    tester,
  ) async {
    await goldenAtSizes(
      tester,
      name: 'all_loans_screen_grouped',
      home: _screen([
        _loan(
          id: 'overdue',
          itemName: 'Drill',
          borrower: 'Bob',
          expectedReturnDate: DateTime.now().subtract(const Duration(days: 3)),
        ),
        _loan(
          id: 'dueSoon',
          itemName: 'Ladder',
          borrower: 'Carol',
          expectedReturnDate: DateTime.now().add(const Duration(days: 2)),
        ),
        _loan(
          id: 'upcoming',
          itemName: 'Tent',
          borrower: 'Dave',
          expectedReturnDate: DateTime.now().add(const Duration(days: 20)),
        ),
      ]),
      textScales: const <double>[1.0, 3.0],
    );
  });
}

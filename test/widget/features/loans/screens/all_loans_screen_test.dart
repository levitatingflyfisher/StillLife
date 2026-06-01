import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/loans/domain/entities/loan.dart';
import 'package:still_life/features/loans/presentation/controllers/loan_controller.dart';
import 'package:still_life/features/loans/presentation/screens/all_loans_screen.dart';

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

Widget _wrap(List<Loan> loans) => ProviderScope(
  overrides: [
    activeLoansProvider.overrideWith((ref) => Stream.value(loans)),
    loanControllerProvider.overrideWith(() => _FakeCtrl()),
  ],
  child: const MaterialApp(home: AllLoansScreen()),
);

class _FakeCtrl extends LoanController {
  @override
  Future<void> build() async {}
  @override
  Future<void> markReturned(String id) async {}
}

void main() {
  testWidgets('shows empty state when no loans', (tester) async {
    await tester.pumpWidget(_wrap([]));
    await tester.pump();
    expect(find.text('No items on loan'), findsOneWidget);
  });

  testWidgets('shows item name and borrower', (tester) async {
    await tester.pumpWidget(_wrap([_loan()]));
    await tester.pump();
    expect(find.text('Camera'), findsOneWidget);
    expect(find.textContaining('Alice'), findsOneWidget);
  });

  testWidgets('groups overdue loans separately', (tester) async {
    final overdue = _loan(
      id: 'l2',
      expectedReturnDate: DateTime.now().subtract(const Duration(days: 2)),
    );
    final upcoming = _loan(id: 'l3');
    await tester.pumpWidget(_wrap([overdue, upcoming]));
    await tester.pump();
    expect(find.text('Overdue'), findsOneWidget); // section header
  });
}

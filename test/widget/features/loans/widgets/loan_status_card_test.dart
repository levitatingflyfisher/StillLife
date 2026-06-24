import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/loans/domain/entities/loan.dart';
import 'package:still_life/features/loans/presentation/widgets/loan_status_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Loan _loan({DateTime? returnedAt, DateTime? expectedReturnDate}) => Loan(
  id: 'l1',
  itemId: 'i1',
  itemName: 'Camera',
  borrowerName: 'Alice',
  returnedAt: returnedAt,
  expectedReturnDate: expectedReturnDate,
  createdAt: DateTime(2025),
  modifiedAt: DateTime(2025),
);

void main() {
  testWidgets('shows active loan info and Mark Returned button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LoanStatusCard(
          loan: _loan(),
          onMarkReturned: () {},
          onEdit: () {},
          onLend: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Mark Returned'), findsOneWidget);
  });

  testWidgets('shows Lend button when no active loan', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LoanStatusCard(
          loan: null,
          onMarkReturned: () {},
          onEdit: () {},
          onLend: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Lend this item'), findsOneWidget);
    expect(find.text('Mark Returned'), findsNothing);
  });

  testWidgets('shows Overdue badge when loan is overdue', (tester) async {
    final loan = _loan(
      expectedReturnDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    await tester.pumpWidget(
      _wrap(
        LoanStatusCard(
          loan: loan,
          onMarkReturned: () {},
          onEdit: () {},
          onLend: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('shows Due Soon badge when loan is due within 3 days', (
    tester,
  ) async {
    final loan = _loan(
      expectedReturnDate: DateTime.now().add(const Duration(days: 2)),
    );
    await tester.pumpWidget(
      _wrap(
        LoanStatusCard(
          loan: loan,
          onMarkReturned: () {},
          onEdit: () {},
          onLend: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Due Soon'), findsOneWidget);
  });
}

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/loans/domain/entities/loan.dart';
import 'package:still_life/features/loans/presentation/widgets/loan_status_card.dart';

import 'visual_golden_helper.dart';

/// Pinned "today". The card renders absolute dates and its overdue/due-soon
/// badges compare against clock.now(), so both the loan dates and the clock
/// must be fixed or the goldens go stale the day after they're recorded.
final DateTime _now = DateTime(2026, 1, 15, 12);

Loan _loan({
  String borrower = 'Alice',
  DateTime? expectedReturnDate,
}) => Loan(
  id: 'l1',
  itemId: 'i1',
  itemName: 'Camera',
  borrowerName: borrower,
  expectedReturnDate: expectedReturnDate,
  createdAt: DateTime(2025),
  modifiedAt: DateTime(2025),
);

Widget _card(Loan? loan) => Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: LoanStatusCard(
        loan: loan,
        onMarkReturned: () {},
        onEdit: () {},
        onLend: () {},
      ),
    ),
  ),
);

const _narrowSizes = <String, Size>{
  'phone': Size(360, 740),
  'narrow': Size(320, 740),
};

void main() {
  testWidgets('LoanStatusCard active loan golden sweep', (tester) async {
    await withClock(Clock.fixed(_now), () => goldenAtSizes(
      tester,
      name: 'loan_status_card_active',
      home: _card(_loan(expectedReturnDate: DateTime(2026, 1, 25))),
      sizes: _narrowSizes,
      textScales: const <double>[1.0, 3.0],
    ));
  });

  testWidgets('LoanStatusCard no-loan golden sweep', (tester) async {
    await withClock(Clock.fixed(_now), () => goldenAtSizes(
      tester,
      name: 'loan_status_card_none',
      home: _card(null),
      sizes: _narrowSizes,
      textScales: const <double>[1.0, 3.0],
    ));
  });

  testWidgets('LoanStatusCard overdue golden sweep', (tester) async {
    await withClock(Clock.fixed(_now), () => goldenAtSizes(
      tester,
      name: 'loan_status_card_overdue',
      home: _card(_loan(expectedReturnDate: DateTime(2026, 1, 13))),
      sizes: _narrowSizes,
      textScales: const <double>[1.0, 3.0],
    ));
  });

  testWidgets('LoanStatusCard due-soon golden sweep', (tester) async {
    await withClock(Clock.fixed(_now), () => goldenAtSizes(
      tester,
      name: 'loan_status_card_due_soon',
      home: _card(_loan(expectedReturnDate: DateTime(2026, 1, 17))),
      sizes: _narrowSizes,
      textScales: const <double>[1.0, 3.0],
    ));
  });
}

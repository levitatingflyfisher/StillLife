import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/loans/domain/entities/loan.dart';
import 'package:still_life/features/loans/presentation/widgets/loan_status_card.dart';

/// Regression test for the Edit + Mark Returned action row overflowing on a
/// narrow (320dp) screen with large accessibility text (×3). The two buttons'
/// natural width exceeded the card width, producing a RenderFlex overflow.
Loan _loan() => Loan(
  id: 'l1',
  itemId: 'i1',
  itemName: 'Camera',
  borrowerName: 'Alice',
  expectedReturnDate: DateTime.now().add(const Duration(days: 2)),
  createdAt: DateTime(2025),
  modifiedAt: DateTime(2025),
);

void main() {
  testWidgets(
    'LoanStatusCard action row does not overflow at 320dp / textScale 3.0',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 740);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
            child: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  child: LoanStatusCard(
                    loan: _loan(),
                    onMarkReturned: () {},
                    onEdit: () {},
                    onLend: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}

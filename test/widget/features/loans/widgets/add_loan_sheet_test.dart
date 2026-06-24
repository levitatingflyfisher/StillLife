import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/loans/domain/entities/loan.dart';
import 'package:still_life/features/loans/presentation/controllers/loan_controller.dart';
import 'package:still_life/features/loans/presentation/widgets/add_loan_sheet.dart';

class _FakeLoanController extends LoanController {
  Loan? lent;
  Loan? edited;
  @override
  Future<void> build() async {}
  @override
  Future<void> lend(Loan loan) async => lent = loan;
  @override
  Future<void> editLoan(Loan loan) async => edited = loan;
}

Widget _wrap(Widget child, LoanController ctrl) => ProviderScope(
  overrides: [loanControllerProvider.overrideWith(() => ctrl)],
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('submit without borrower name shows validation error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ctrl = _FakeLoanController();
    await tester.pumpWidget(
      _wrap(const AddLoanSheet(itemId: 'item-1', itemName: 'Camera'), ctrl),
    );
    await tester.pump();

    await tester.tap(find.text('Lend'));
    await tester.pump();

    expect(find.text('Borrower name is required'), findsOneWidget);
    expect(ctrl.lent, isNull);
  });

  testWidgets('submit with borrower name calls loanController.lend', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ctrl = _FakeLoanController();
    await tester.pumpWidget(
      _wrap(const AddLoanSheet(itemId: 'item-1', itemName: 'Camera'), ctrl),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'Bob');
    await tester.tap(find.text('Lend'));
    await tester.pump();

    expect(ctrl.lent, isNotNull);
    expect(ctrl.lent!.borrowerName, 'Bob');
    expect(ctrl.lent!.itemId, 'item-1');
  });

  testWidgets('edit mode shows Save button and calls editLoan', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final existingLoan = Loan(
      id: 'existing-id',
      itemId: 'item-1',
      itemName: 'Camera',
      borrowerName: 'Alice',
      createdAt: DateTime(2025),
      modifiedAt: DateTime(2025),
    );
    final ctrl = _FakeLoanController();
    await tester.pumpWidget(
      _wrap(
        AddLoanSheet(
          itemId: 'item-1',
          itemName: 'Camera',
          editingLoan: existingLoan,
        ),
        ctrl,
      ),
    );
    await tester.pump();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Lend'), findsNothing);

    // Change the borrower name
    await tester.enterText(find.byType(TextFormField).first, 'Bob');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(ctrl.edited, isNotNull);
    expect(ctrl.edited!.borrowerName, 'Bob');
    expect(ctrl.edited!.id, 'existing-id'); // preserves the original ID
  });
}

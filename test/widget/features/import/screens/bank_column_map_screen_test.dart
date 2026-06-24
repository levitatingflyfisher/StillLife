import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:still_life/features/import/presentation/screens/bank_column_map_screen.dart';
import 'package:still_life/services/import/bank_statement_parser.dart';

void main() {
  const testCsv =
      'Date,Description,Amount\n2024-01-15,Coffee,12.50\n2024-01-16,Grocery,8.00\n';

  Widget buildTestWidget({
    BankColumnMap autoDetected = const BankColumnMap(),
    bool truncated = false,
  }) {
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => BankColumnMapScreen(
                csvContent: testCsv,
                autoDetected: autoDetected,
                truncated: truncated,
              ),
            ),
            GoRoute(
              path: '/import/review',
              name: 'importReview',
              builder: (context, state) =>
                  const Scaffold(body: Text('Review Screen')),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('shows three column dropdowns', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    expect(find.text('Date column'), findsOneWidget);
    expect(find.text('Description column'), findsOneWidget);
    expect(find.text('Amount column'), findsOneWidget);
  });

  testWidgets('Continue button disabled when no columns assigned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'Continue button enabled when all columns assigned via auto-detect',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        buildTestWidget(
          autoDetected: const BankColumnMap(
            dateCol: 0,
            descriptionCol: 1,
            amountCol: 2,
          ),
        ),
      );
      await tester.pump();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets('shows snackbar for truncated CSV before navigating', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      buildTestWidget(
        autoDetected: const BankColumnMap(
          dateCol: 0,
          descriptionCol: 1,
          amountCol: 2,
        ),
        truncated: true,
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(
      find.text('Only the first 500 rows will be imported.'),
      findsOneWidget,
    );
  });
}

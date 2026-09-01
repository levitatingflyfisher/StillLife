import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:still_life/features/reports/domain/entities/policy.dart';
import 'package:still_life/features/reports/presentation/controllers/policy_controller.dart';
import 'package:still_life/features/reports/presentation/screens/reports_screen.dart';

void main() {
  group('ReportsScreen', () {
    Widget buildSubject({
      DashboardSummary? summary,
      List<Policy> policies = const [],
    }) {
      return ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith(
            (ref) async => summary ?? const DashboardSummary(),
          ),
          policiesProvider.overrideWith(
            (_) => Stream<List<Policy>>.value(policies),
          ),
        ],
        child: const MaterialApp(home: ReportsScreen()),
      );
    }

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays financial overview after loading', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          summary: const DashboardSummary(
            totalItems: 42,
            totalCurrentValueCents: 1500000,
            totalReplacementCostCents: 2000000,
            totalAcquisitionCostCents: 1800000,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Overview'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('total coverage prints stored cents as dollars', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          policies: [
            Policy(
              id: 'p1',
              propertyId: 'prop1',
              provider: 'Acme Mutual',
              coverageAmountCents: 12345,
              createdAt: DateTime(2025, 6, 1),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(r'$123.45'), findsOneWidget);
      expect(find.text(r'$12,345.00'), findsNothing);
    });

    testWidgets('displays export options', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Export Data'), findsOneWidget);
      expect(find.text('Insurance Report (PDF)'), findsOneWidget);
    });

    testWidgets('displays import option after scrolling', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Import Data'),
        200,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('Import Data'), findsOneWidget);
      expect(find.text('Import from JSON'), findsOneWidget);
    });

    testWidgets('PDF export button is present and tappable', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final pdfButton = find.text('Insurance Report (PDF)');
      expect(pdfButton, findsOneWidget);
      // Tap should not crash the widget.
      await tester.tap(pdfButton);
      await tester.pump();
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:still_life/features/dashboard/presentation/widgets/stat_card.dart';

void main() {
  group('StatCard', () {
    testWidgets('displays title, value, and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Total Items',
              value: '42',
              icon: Icons.inventory_2_outlined,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Total Items'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });

  group('DashboardSummary', () {
    test('has zero defaults', () {
      const summary = DashboardSummary();
      expect(summary.totalItems, 0);
      expect(summary.totalCurrentValue, 0.0);
      expect(summary.totalReplacementCost, 0.0);
      expect(summary.totalAcquisitionCost, 0.0);
      expect(summary.valueByRoom, isEmpty);
      expect(summary.valueByCategory, isEmpty);
    });
  });
}

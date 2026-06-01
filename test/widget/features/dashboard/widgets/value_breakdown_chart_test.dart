import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/dashboard/presentation/widgets/value_breakdown_chart.dart';

void main() {
  group('ValueBreakdownChart', () {
    testWidgets('shows "No data" when data is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: ValueBreakdownChart(data: {}),
            ),
          ),
        ),
      );

      expect(find.text('No data'), findsOneWidget);
    });

    testWidgets('shows "No data" when all values are zero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: ValueBreakdownChart(data: {'A': 0, 'B': 0}),
            ),
          ),
        ),
      );

      expect(find.text('No data'), findsOneWidget);
    });

    testWidgets('displays legend entries for data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: ValueBreakdownChart(
                data: {'Electronics': 5000.0, 'Furniture': 3000.0},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Electronics'), findsOneWidget);
      expect(find.text('Furniture'), findsOneWidget);
    });

    testWidgets('limits legend to 6 entries', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: ValueBreakdownChart(
                data: {
                  'Cat 1': 100,
                  'Cat 2': 200,
                  'Cat 3': 300,
                  'Cat 4': 400,
                  'Cat 5': 500,
                  'Cat 6': 600,
                  'Cat 7': 700,
                },
              ),
            ),
          ),
        ),
      );

      // The 7th category should not appear in the legend
      expect(find.text('Cat 7'), findsOneWidget); // highest, shown first
      expect(find.text('Cat 1'), findsNothing); // lowest, cut off
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:still_life/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:still_life/features/dashboard/presentation/widgets/stat_grid.dart';

void main() {
  testWidgets('no headline figure is painted in error red', (tester) async {
    final theme = OhTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: StatGrid(
            summary: DashboardSummary(
              totalItems: 3,
              totalCurrentValueCents: 120000,
              totalReplacementCostCents: 150000,
              totalAcquisitionCostCents: 99900,
            ),
          ),
        ),
      ),
    );
    final error = theme.colorScheme.error;
    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      expect(t.style?.color, isNot(error), reason: t.data);
    }
    for (final i in tester.widgetList<Icon>(find.byType(Icon))) {
      expect(i.color, isNot(error));
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  // Audit finding 7: at 360dp the tile titles read "Replacement …" and
  // "Acquisition C…". A title may wrap; nothing in a tile is ever cut off,
  // and the money figure is never ellipsized.
  for (final (width, scale) in const [(360.0, 1.0), (360.0, 1.3), (320.0, 2.0), (320.0, 3.0)]) {
    testWidgets('no tile text is cut off at ${width}dp x $scale', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: OhTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: TextScaler.linear(scale),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: OhSpacing.insetMd,
                child: StatGrid(
                  summary: DashboardSummary(
                    totalItems: 1234,
                    totalCurrentValueCents: 12345678,
                    totalReplacementCostCents: 23456789,
                    totalAcquisitionCostCents: 9876543,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      for (final label in const [
        'Total Items',
        'Total Value',
        'Replacement Cost',
        'Acquisition Cost',
        r'$123,456.78',
        r'$234,567.89',
        r'$98,765.43',
      ]) {
        final finder = find.text(label);
        expect(finder, findsOneWidget, reason: label);
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        expect(paragraph.didExceedMaxLines, isFalse, reason: '$label is cut off');
      }
      expect(tester.takeException(), isNull);
    });
  }
}

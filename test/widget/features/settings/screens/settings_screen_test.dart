import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/settings/presentation/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    Widget buildSubject() {
      return const ProviderScope(child: MaterialApp(home: SettingsScreen()));
    }

    testWidgets('displays top section headers', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      // Section header + list tile both say 'AI Analysis'
      expect(find.text('AI Analysis'), findsNWidgets(2));
    });

    testWidgets('displays theme setting', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget); // default theme mode
    });

    testWidgets('displays about section after scrolling', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.scrollUntilVisible(
        find.text('AGPL-3.0 (Community Edition)'),
        200,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('Still Life'), findsOneWidget);
      // Version string is now sourced from package_info_plus at runtime
      // (default "Version …" while async-loading in tests).
      expect(find.textContaining('Version'), findsWidgets);
      expect(find.text('AGPL-3.0 (Community Edition)'), findsOneWidget);
    });

    testWidgets('displays privacy statement after scrolling', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.scrollUntilVisible(
        find.text('No telemetry. No ads. Your data stays on your device.'),
        200,
        scrollable: find.byType(Scrollable),
      );

      expect(
        find.text('No telemetry. No ads. Your data stays on your device.'),
        findsOneWidget,
      );
    });

    testWidgets('opens theme dialog on tap', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Theme'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('selecting a theme mode updates the setting', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Open dialog
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      // Select Dark
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Theme subtitle should now show 'Dark'
      expect(find.text('Dark'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/settings/presentation/screens/settings_screen.dart';

import '../../../../mocks/fake_secure_storage_channel.dart';

void main() {
  group('SettingsScreen', () {
    // sanctuary_backup_ui 0.3.0 draws its section in every state; with no
    // keystore answering, it would sit on "Checking backup status…" and
    // its spinner never lets pumpAndSettle settle.
    final storage = FakeSecureStorageChannel();
    setUp(storage.install);
    tearDown(storage.uninstall);

    Widget buildSubject() {
      return const ProviderScope(child: MaterialApp(home: SettingsScreen()));
    }

    // A tall phone, so the top sections are laid out without scrolling as
    // the list grows (Recently deleted added a row under Inventory).
    Future<void> pumpSubject(WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildSubject());
    }

    testWidgets('displays top section headers', (tester) async {
      await pumpSubject(tester);

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      // Section header + list tile both say 'AI Analysis'
      expect(find.text('AI Analysis'), findsNWidgets(2));
    });

    testWidgets('displays theme setting', (tester) async {
      await pumpSubject(tester);

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Follow phone'), findsOneWidget); // default theme mode
    });

    testWidgets('displays about section after scrolling', (tester) async {
      await pumpSubject(tester);

      await tester.scrollUntilVisible(
        find.text('MIT'),
        200,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('Still Life'), findsOneWidget);
      // Version string is now sourced from package_info_plus at runtime
      // (default "Version …" while async-loading in tests).
      expect(find.textContaining('Version'), findsWidgets);
      expect(find.text('MIT'), findsOneWidget);
    });

    testWidgets('displays privacy statement after scrolling', (tester) async {
      await pumpSubject(tester);

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

    testWidgets('import options offer receipt camera alongside gallery', (
      tester,
    ) async {
      await pumpSubject(tester);

      await tester.scrollUntilVisible(
        find.text('Import items'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.text('Import items'));
      await tester.pumpAndSettle();

      expect(find.text('Receipt camera'), findsOneWidget);
      expect(find.text('Receipt photo'), findsOneWidget);
      expect(find.text('Amazon order export'), findsOneWidget);
      expect(find.text('Bank statement'), findsOneWidget);
    });

    testWidgets('Amazon import help explains the Privacy Central path', (
      tester,
    ) async {
      await pumpSubject(tester);

      await tester.scrollUntilVisible(
        find.text('Import items'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.text('Import items'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('How do I get this file?'));
      await tester.pumpAndSettle();

      expect(find.text('How do I get this file?'), findsOneWidget);
      expect(
        find.textContaining('Privacy Central'),
        findsOneWidget,
      );
      expect(find.textContaining('Request My Data'), findsOneWidget);
      expect(find.textContaining('Your Orders'), findsOneWidget);
      expect(find.textContaining('Retail.OrderHistory'), findsOneWidget);
      // Desktop alternatives by name only — no links, no install steps.
      expect(find.textContaining('azad'), findsOneWidget);
      expect(find.textContaining('amazon-orders'), findsOneWidget);
    });

    testWidgets('opens theme dialog on tap', (tester) async {
      await pumpSubject(tester);

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Follow phone'), findsNWidgets(2));
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('selecting a theme mode updates the setting', (tester) async {
      await pumpSubject(tester);

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

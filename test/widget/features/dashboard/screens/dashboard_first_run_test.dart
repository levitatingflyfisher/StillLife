import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/core/providers/sync_providers.dart';
import 'package:still_life/core/sync/sync_stamp.dart';
import 'package:still_life/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:still_life/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:still_life/services/database/database.dart' hide Item;

import '../../../../test_setup.dart';

/// Audit finding 6 (ruling 48, open into the task): at 0 items the
/// Dashboard used to show four $0.00 tiles and "nothing" cards, with Add
/// Your First Item last. First run now says what the app is for and puts
/// the way to begin first.
Finder _filled(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    );

void main() {
  ensureSqlite3();

  Future<AppDatabase> pump(WidgetTester tester, Size size, double scale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase.memory();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sanctuaryBackupConfigProvider.overrideWithValue(
            const SanctuaryBackupConfig(
              appId: 'stilllife',
              aadContext: 'stilllife-backup/v1',
              appDisplayName: 'Still Life',
            ),
          ),
          databaseProvider.overrideWithValue(db),
          syncStampProvider.overrideWithValue(SyncStamp.none),
          secureKeyStoreProvider.overrideWithValue(InMemorySecureKeyStore()),
          cryptoServiceProvider.overrideWithValue(FakeCryptoService()),
          backupReminderStoreProvider.overrideWithValue(
            InMemoryBackupReminderStore(),
          ),
          dashboardSummaryProvider.overrideWith(
            (ref) async => const DashboardSummary(),
          ),
        ],
        child: MaterialApp(
          theme: OhTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
            child: const DashboardScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return db;
  }

  Future<void> close(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(db.close);
  }

  testWidgets(r'first run leads with the way to begin, not $0.00 tiles', (
    tester,
  ) async {
    final db = await pump(tester, const Size(360, 800), 1.3);
    expect(find.text(r'$0.00'), findsNothing);
    expect(find.text('Total Items'), findsNothing);
    expect(find.textContaining('starts from a list'), findsOneWidget);
    expect(find.textContaining('One room is enough'), findsOneWidget);
    final add = _filled('Add item');
    expect(add, findsOneWidget);
    // On screen without scrolling at 360dp x 1.3.
    final rect = tester.getRect(add);
    expect(rect.bottom, lessThanOrEqualTo(800));
    expect(add.hitTestable(), findsOneWidget);
    await close(tester, db);
  });

  testWidgets('first run fits at 320dp x 3.0', (tester) async {
    final db = await pump(tester, const Size(320, 700), 3.0);
    expect(tester.takeException(), isNull);
    // The package's backup reminder fills most of a 320dp screen at 3.0;
    // the way to begin is the next thing below it.
    await tester.scrollUntilVisible(find.text('Add item'), 200);
    expect(tester.takeException(), isNull);
    expect(_filled('Add item'), findsOneWidget);
    await close(tester, db);
  });
}

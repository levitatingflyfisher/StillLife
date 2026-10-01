import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/core/providers/profile_providers.dart';
import 'package:still_life/features/inventory/presentation/screens/item_edit_screen.dart';
import 'package:still_life/features/profiles/domain/entities/profile.dart'
    as domain;
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';
import 'package:still_life/core/providers/sync_providers.dart';
import 'package:still_life/core/sync/sync_stamp.dart';

class _NoProfile extends ActiveProfileNotifier {
  @override
  Future<domain.Profile?> build() async => null;
}

/// about-face-07 (full remedy, ruling Q-S4): what is typed into Add Item
/// is kept as a draft as it is typed, on this device only (never synced),
/// so leaving by any route (the app killed in the background, a tab, a
/// deep link) loses nothing. The next Add picks up where it left off, with
/// Start over. Saving or discarding ends the draft. Back still asks.
void main() {
  ensureSqlite3();
  late AppDatabase db;
  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<void> open(
    WidgetTester tester, {
    Widget screen = const ItemEditScreen(),
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/add'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(path: '/add', builder: (_, _) => screen),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // No keystore in widget tests: writes go unstamped.
          syncStampProvider.overrideWithValue(SyncStamp.none),
          activeProfileProvider.overrideWith(_NoProfile.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
  }

  testWidgets('typed work survives the screen going away and comes back '
      'on the next Add', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Walnut desk');
    await tester.pump(const Duration(milliseconds: 100));
    // The app is killed: no back, no dialog.
    await unmount(tester);

    await open(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Walnut desk'), findsOneWidget);
    expect(find.text('Picked up where you left off.'), findsOneWidget);

    await tester.tap(find.text('Start over'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Walnut desk'), findsNothing);
    expect(find.text('Picked up where you left off.'), findsNothing);
    await unmount(tester);

    await open(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Picked up where you left off.'), findsNothing,
        reason: 'Start over ended the draft');
    await unmount(tester);
  });

  testWidgets('Discard on Back ends the draft', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Old lamp');
    await tester.pump(const Duration(milliseconds: 100));
    await back(tester);
    await tester.tap(find.text('Discard item'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await unmount(tester);

    await open(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Old lamp'), findsNothing);
    expect(find.text('Picked up where you left off.'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a draft lives only on this device: no synced table holds it',
      (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Walnut desk');
    await tester.pump(const Duration(milliseconds: 100));
    await unmount(tester);
    final items = await tester.runAsync(() => db.select(db.items).get());
    expect(items, isEmpty, reason: 'a half-typed item is not an item');
    final drafts = await tester.runAsync(() => db.select(db.itemDrafts).get());
    expect(drafts, hasLength(1));
  });

  // A barcode scan or a room's Add opens a prefilled form: a kept draft
  // must not overwrite the scanned code or move the item to another room.
  testWidgets('a prefilled Add (a scan) is not overwritten by a draft',
      (tester) async {
    // Tall, so the lazy form builds the barcode field deep in the list.
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Walnut desk');
    await tester.pump(const Duration(milliseconds: 100));
    await unmount(tester);

    await open(tester, screen: const ItemEditScreen(initialBarcode: '0123'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byWidgetPredicate(
          (w) => w is EditableText && w.controller.text == '0123'),
      findsOneWidget,
    );
    expect(find.text('Walnut desk'), findsNothing);
    expect(find.text('Picked up where you left off.'), findsNothing);
    await unmount(tester);

    // The plain Add still has its draft.
    await open(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Walnut desk'), findsOneWidget);
    await unmount(tester);
  });
}

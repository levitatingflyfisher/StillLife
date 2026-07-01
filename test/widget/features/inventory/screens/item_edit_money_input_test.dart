import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/core/providers/profile_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item_suggestion.dart';
import 'package:still_life/features/inventory/presentation/screens/item_edit_screen.dart';
import 'package:still_life/features/profiles/domain/entities/profile.dart'
    as domain;
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

/// Money-input behavior on the edit form: comma-decimal input must not be
/// silently dropped, and garbage must surface a field error instead of
/// saving without a price.
class _FakeActiveProfileNotifier extends ActiveProfileNotifier {
  @override
  Future<domain.Profile?> build() async => null;
}

void main() {
  ensureSqlite3();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    final now = DateTime(2026);
    await db.into(db.properties).insert(PropertiesCompanion.insert(
        id: 'prop-1', name: 'Home', createdAt: now, modifiedAt: now));
    await db.into(db.rooms).insert(RoomsCompanion.insert(
        id: 'room-1',
        propertyId: 'prop-1',
        name: 'Garage',
        createdAt: now,
        modifiedAt: now));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat-1', name: 'Tools', createdAt: now, modifiedAt: now));
  });

  tearDown(() => db.close());

  Future<void> pumpEditScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(800, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/edit'),
                child: const Text('open-edit'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/edit', builder: (context, state) => screen),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeProfileProvider.overrideWith(_FakeActiveProfileNotifier.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('open-edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
  }

  Future<void> saveAndSettle(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('comma-decimal purchase price persists instead of being dropped',
      (tester) async {
    await pumpEditScreen(
      tester,
      const ItemEditScreen(
        initialRoomId: 'room-1',
        initialSuggestion: ItemSuggestion(
          name: 'Impact driver',
          categoryName: 'Tools',
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Purchase Price'),
      '12,50',
    );
    await saveAndSettle(tester);

    final rows = await db.select(db.items).get();
    expect(rows, hasLength(1));
    expect(rows.single.purchasePriceCents, 1250,
        reason: 'comma-decimal money must parse, not silently drop');

    await unmount(tester);
  });

  testWidgets('typed money rounds to cents at the write boundary',
      (tester) async {
    await pumpEditScreen(
      tester,
      const ItemEditScreen(
        initialRoomId: 'room-1',
        initialSuggestion: ItemSuggestion(
          name: 'Impact driver',
          categoryName: 'Tools',
        ),
      ),
    );

    // 1234.005's nearest double sits a hair below the half-cent — a raw
    // parse would persist a fractional cent. The rounding law says 1234.01
    // lands. (The old '1.005' probe is now rejected as ambiguous grouping;
    // a 4-digit integer part keeps the input unambiguously decimal.)
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Purchase Price'),
      '1234.005',
    );
    await saveAndSettle(tester);

    final rows = await db.select(db.items).get();
    expect(rows, hasLength(1));
    expect(rows.single.purchasePriceCents, 123401,
        reason: 'money writes must round to cents at the write boundary');

    await unmount(tester);
  });

  testWidgets('unparseable price shows a field error and blocks the save',
      (tester) async {
    await pumpEditScreen(
      tester,
      const ItemEditScreen(
        initialRoomId: 'room-1',
        initialSuggestion: ItemSuggestion(
          name: 'Impact driver',
          categoryName: 'Tools',
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Purchase Price'),
      '1,2,3',
    );
    await saveAndSettle(tester);

    expect(find.text('Enter a valid amount'), findsOneWidget,
        reason: 'the field must surface a validation error');
    final rows = await db.select(db.items).get();
    expect(rows, isEmpty,
        reason: 'nothing may save while a money field is unparseable');

    await unmount(tester);
  });

  testWidgets(
      'ambiguous "1,234" shows the actionable message and blocks the save',
      (tester) async {
    await pumpEditScreen(
      tester,
      const ItemEditScreen(
        initialRoomId: 'room-1',
        initialSuggestion: ItemSuggestion(
          name: 'Impact driver',
          categoryName: 'Tools',
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Purchase Price'),
      '1,234',
    );
    await saveAndSettle(tester);

    expect(find.text('Ambiguous amount — use 1234 or 1,234.00'), findsOneWidget,
        reason: 'the US-thousands reading must be refused, not saved as 1.23');
    final rows = await db.select(db.items).get();
    expect(rows, isEmpty,
        reason: 'nothing may save while a money field is ambiguous');

    await unmount(tester);
  });

  testWidgets(
      'garbage price scrolled out of a phone viewport still blocks the save '
      '(lazy-ListView unmount regression)', (tester) async {
    // Phone-sized viewport: the form's lazy ListView UNMOUNTS the money row
    // once it scrolls past the cache extent, deregistering its validator
    // from the Form — Form.validate() alone would pass over garbage and
    // save a silent null price.
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/edit'),
                child: const Text('open-edit'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) => const ItemEditScreen(
            initialRoomId: 'room-1',
            initialSuggestion: ItemSuggestion(
              name: 'Impact driver',
              categoryName: 'Tools',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeProfileProvider.overrideWith(_FakeActiveProfileNotifier.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('open-edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final scrollable = find.byType(Scrollable).first;
    final priceField = find.widgetWithText(TextFormField, 'Purchase Price');

    // Scroll the money row into view and type garbage.
    await tester.scrollUntilVisible(priceField, 150, scrollable: scrollable);
    await tester.pump();
    await tester.enterText(priceField, '1,2,3');
    await tester.pump();

    // Move focus off the money field (releasing its keep-alive) …
    final serialField = find.widgetWithText(TextFormField, 'Serial Number');
    await tester.scrollUntilVisible(serialField, 150, scrollable: scrollable);
    await tester.pump();
    await tester.tap(serialField);
    await tester.pump();

    // … then scroll far past the cache extent so the row unmounts.
    await tester.drag(scrollable, const Offset(0, -2000));
    await tester.pump();
    await tester.drag(scrollable, const Offset(0, -2000));
    await tester.pump();
    expect(priceField, findsNothing,
        reason: 'precondition: the money row must be lazily unmounted');

    // Save from the always-visible AppBar action.
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // The fix: _save checks the money controllers' TEXT regardless of mount
    // state — the garbage must block the save and surface an error.
    final rows = await db.select(db.items).get();
    expect(rows, isEmpty,
        reason: 'an unmounted garbage money field must still block the save');
    expect(find.text('Purchase Price: Enter a valid amount'), findsOneWidget,
        reason: 'the refusal must be surfaced, not silent');

    await unmount(tester);
  });
}

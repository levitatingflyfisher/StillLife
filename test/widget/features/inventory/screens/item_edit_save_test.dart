import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
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

/// End-to-end save-path tests: a real in-memory database behind the real
/// repositories, so what the form claims to save is what lands in columns.
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
    // Bounded pumps, not pumpAndSettle: drift watch streams + image decode
    // keep scheduling work that never fully settles under fake async.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

  }

  /// Must be the last line of every test body: disposes the ProviderScope
  /// (closing drift query streams) and flushes their zero-duration close
  /// timers, which would otherwise trip the pending-timer invariant and
  /// wedge `db.close()` in tearDown.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // Non-zero duration: drift's close notification is a zero-duration
    // timer, and only an elapsing pump fires it under fake async.
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
  }

  Future<void> saveAndSettle(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
      'add flow saves suggestion-prefilled brand and typed model to the row',
      (tester) async {
    await pumpEditScreen(
      tester,
      const ItemEditScreen(
        initialRoomId: 'room-1',
        initialSuggestion: ItemSuggestion(
          name: 'Impact driver',
          categoryName: 'Tools',
          brand: 'Bosch',
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Model'),
      'GDX 18V-200',
    );
    await saveAndSettle(tester);

    final rows = await db.select(db.items).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, 'Impact driver');
    expect(rows.single.brand, 'Bosch',
        reason: 'suggestion-prefilled brand must persist');
    expect(rows.single.model, 'GDX 18V-200',
        reason: 'typed model must persist');
    expect(rows.single.asin, isNull);

    await unmount(tester);
  });

  testWidgets(
      'photo-add shows a thumbnail and attaches the photo to the saved item',
      (tester) async {
    final photoBytes = Uint8List.fromList([9, 8, 7]);
    await pumpEditScreen(
      tester,
      ItemEditScreen(
        initialRoomId: 'room-1',
        initialSuggestion: ItemSuggestion(
          name: 'Reading lamp',
          categoryName: 'Tools',
          photoBytes: photoBytes,
        ),
      ),
    );

    // The user can see the photo will attach.
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
      findsOneWidget,
      reason: 'the add form must preview the captured photo',
    );

    await saveAndSettle(tester);

    final items = await db.select(db.items).get();
    expect(items, hasLength(1));
    final photos = await db.select(db.photos).get();
    expect(photos, hasLength(1),
        reason: 'the captured photo must survive to the saved item');
    expect(photos.single.itemId, items.single.id);
    expect(photos.single.bytes, photoBytes);
    expect(photos.single.source, 'camera');

    await unmount(tester);
  });

  testWidgets('editing an item preserves its receipt link (receiptId)',
      (tester) async {
    final now = DateTime(2026);
    await db.into(db.receipts).insert(ReceiptsCompanion.insert(
        id: 'receipt-1', photoPath: '', createdAt: now));
    await db.into(db.items).insert(ItemsCompanion.insert(
        id: 'item-r1',
        name: 'Coffee Grinder',
        categoryId: 'cat-1',
        roomId: 'room-1',
        receiptId: const Value('receipt-1'),
        createdAt: now,
        modifiedAt: now));

    await pumpEditScreen(tester, const ItemEditScreen(itemId: 'item-r1'));

    // Edit any field — fix a typo in the name.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name *'),
      'Coffee Grinder Pro',
    );
    await saveAndSettle(tester);

    final row =
        await (db.select(db.items)..where((t) => t.id.equals('item-r1')))
            .getSingle();
    expect(row.name, 'Coffee Grinder Pro');
    expect(row.receiptId, 'receipt-1',
        reason: 'receiptId has no form field, so an edit must not sever '
            'the receipt link');

    await unmount(tester);
  });

  testWidgets('editing an item preserves a programmatically-set ASIN',
      (tester) async {
    final now = DateTime(2026);
    await db.into(db.items).insert(ItemsCompanion.insert(
        id: 'item-1',
        name: 'Headphones',
        categoryId: 'cat-1',
        roomId: 'room-1',
        brand: const Value('Sony'),
        model: const Value('WH-1000XM4'),
        asin: const Value('B0863TXGM3'),
        createdAt: now,
        modifiedAt: now));

    await pumpEditScreen(tester, const ItemEditScreen(itemId: 'item-1'));

    // Brand/model load into their fields.
    expect(find.widgetWithText(TextFormField, 'Brand'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == 'Sony',
      ),
      findsOneWidget,
    );

    await saveAndSettle(tester);

    final row = await (db.select(db.items)..where((t) => t.id.equals('item-1')))
        .getSingle();
    expect(row.asin, 'B0863TXGM3',
        reason: 'ASIN has no form field, so an edit must not wipe it');
    expect(row.brand, 'Sony');
    expect(row.model, 'WH-1000XM4');

    await unmount(tester);
  });
}

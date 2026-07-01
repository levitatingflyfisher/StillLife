import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/services/import/import_fallback_seeder.dart';
import 'package:still_life/core/providers/profile_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item_suggestion.dart';
import 'package:still_life/features/inventory/presentation/screens/shelf_review_screen.dart';
import 'package:still_life/features/profiles/domain/entities/profile.dart'
    as domain;
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

/// Shelf-review save-path tests: a real in-memory database behind the real
/// repositories, so what the review screen claims to save is what lands
/// in columns — and the shelf photo really attaches to every created item.
class _FakeActiveProfileNotifier extends ActiveProfileNotifier {
  @override
  Future<domain.Profile?> build() async => null;
}

/// A save-path dependency that throws — the screen must SAY the save
/// failed, not reset the spinner and go quiet.
class _ThrowingSeeder extends Fake implements ImportFallbackSeeder {
  @override
  Future<(String, String)> ensureDefaults() async =>
      throw StateError('database is locked');
}

void main() {
  ensureSqlite3();

  late AppDatabase db;
  final shelfPhoto = Uint8List.fromList([42, 43, 44]);

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
    await db.into(db.rooms).insert(RoomsCompanion.insert(
        id: 'room-2',
        propertyId: 'prop-1',
        name: 'Attic',
        createdAt: now,
        modifiedAt: now));
    await db.into(db.storageContainers).insert(
        StorageContainersCompanion.insert(
            id: 'cont-1',
            roomId: 'room-1',
            name: 'Shelf A',
            createdAt: now,
            modifiedAt: now));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat-tools', name: 'Tools', createdAt: now, modifiedAt: now));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat-books',
        name: 'Books & Media',
        createdAt: now,
        modifiedAt: now));
  });

  tearDown(() => db.close());

  Future<void> pumpReviewScreen(
    WidgetTester tester,
    ShelfReviewArgs args, {
    List<Override> extraOverrides = const [],
  }) async {
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
                onPressed: () => context.push('/review'),
                child: const Text('open-review'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) => ShelfReviewScreen(args: args),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeProfileProvider.overrideWith(_FakeActiveProfileNotifier.new),
          ...extraOverrides,
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('open-review'));
    // Bounded pumps, not pumpAndSettle: drift watch streams keep
    // scheduling work that never fully settles under fake async.
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
      'renders one editable row per suggestion — checkbox on by default, '
      'brand/model/value/confidence visible', (tester) async {
    await pumpReviewScreen(
      tester,
      ShelfReviewArgs(
        suggestions: const [
          ItemSuggestion(
            name: 'Bosch Drill',
            brand: 'Bosch',
            model: 'GSB 18V-55',
            categoryName: 'Tools',
            estimatedValue: 129.99,
            confidence: 0.9,
          ),
          ItemSuggestion(
            name: 'Old Paperback',
            categoryName: 'Books',
            confidence: 0.6,
          ),
        ],
        photoBytes: shelfPhoto,
        roomId: 'room-1',
      ),
    );

    final checkboxes = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .toList();
    expect(checkboxes, hasLength(2));
    expect(checkboxes.every((c) => c.value == true), isTrue,
        reason: 'every suggestion starts accepted');

    // Names are inline-editable text fields, not static labels.
    expect(
      find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == 'Bosch Drill',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Bosch'), findsWidgets);
    expect(find.textContaining('GSB 18V-55'), findsOneWidget);
    expect(find.textContaining('129.99'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets(
      'save creates only the accepted items with edited names, matched '
      'categories, cents-rounded values, brand/model — and attaches the '
      'full shelf photo to each (source: camera)', (tester) async {
    await pumpReviewScreen(
      tester,
      ShelfReviewArgs(
        suggestions: const [
          ItemSuggestion(
            name: 'Bosch Drill',
            brand: 'Bosch',
            model: 'GSB 18V-55',
            categoryName: 'Tools',
            estimatedValue: 129.987,
            confidence: 0.9,
          ),
          ItemSuggestion(
            name: 'Old Paperback',
            categoryName: 'Books',
            confidence: 0.6,
          ),
          ItemSuggestion(
            name: 'Mystery Gadget',
            categoryName: 'Whatsit',
            confidence: 0.3,
          ),
          ItemSuggestion(name: 'Rejected Thing', confidence: 0.2),
        ],
        photoBytes: shelfPhoto,
        roomId: 'room-1',
        containerId: 'cont-1',
      ),
    );

    // Inline-edit the first name.
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == 'Bosch Drill',
      ),
      'Renamed Drill',
    );
    // Reject the last suggestion.
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();

    await saveAndSettle(tester);

    final items = await db.select(db.items).get();
    expect(items, hasLength(3), reason: 'the unchecked row must not save');
    expect(items.map((i) => i.name), isNot(contains('Rejected Thing')));

    final drill = items.singleWhere((i) => i.name == 'Renamed Drill');
    expect(drill.brand, 'Bosch');
    expect(drill.model, 'GSB 18V-55');
    expect(drill.categoryId, 'cat-tools',
        reason: 'exact category names match case-insensitively');
    expect(drill.currentValueCents, 12999,
        reason: 'money written by the shelf flow is rounded to cents');
    expect(drill.roomId, 'room-1');
    expect(drill.containerId, 'cont-1',
        reason: 'the batch container applies to every accepted item');

    final paperback = items.singleWhere((i) => i.name == 'Old Paperback');
    expect(paperback.categoryId, 'cat-books',
        reason: '"Books" should match the app\'s "Books & Media" category');

    final gadget = items.singleWhere((i) => i.name == 'Mystery Gadget');
    final importsCat = await (db.select(db.categories)
          ..where((c) => c.name.equals('Imports')))
        .getSingle();
    expect(gadget.categoryId, importsCat.id,
        reason: 'unknown categories fall back to the Imports seeder');

    final photos = await db.select(db.photos).get();
    expect(photos, hasLength(3),
        reason: 'every accepted item gets the shelf photo');
    expect(photos.map((p) => p.itemId).toSet(),
        items.map((i) => i.id).toSet());
    for (final p in photos) {
      expect(p.bytes, shelfPhoto,
          reason: 'the FULL frame attaches — no fake cropping');
      expect(p.source, 'camera');
    }

    await unmount(tester);
  });

  testWidgets('the batch room picker re-homes every accepted item',
      (tester) async {
    await pumpReviewScreen(
      tester,
      ShelfReviewArgs(
        suggestions: const [
          ItemSuggestion(name: 'Lamp', categoryName: 'Other', confidence: 0.8),
          ItemSuggestion(name: 'Vase', categoryName: 'Other', confidence: 0.7),
        ],
        photoBytes: shelfPhoto,
        roomId: 'room-1',
      ),
    );

    // Move the whole batch from Garage to Attic.
    await tester.tap(find.text('Garage'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Attic').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await saveAndSettle(tester);

    final items = await db.select(db.items).get();
    expect(items, hasLength(2));
    for (final item in items) {
      expect(item.roomId, 'room-2',
          reason: 'the batch room picker applies to every item');
    }

    await unmount(tester);
  });

  testWidgets('a thrown save surfaces a snackbar and keeps the screen — '
      'silence would leave the user unsure whether items saved',
      (tester) async {
    await pumpReviewScreen(
      tester,
      ShelfReviewArgs(
        suggestions: const [ItemSuggestion(name: 'Drill')],
        photoBytes: shelfPhoto,
      ),
      extraOverrides: [
        importFallbackSeederProvider.overrideWithValue(_ThrowingSeeder()),
      ],
    );

    await saveAndSettle(tester);

    expect(find.textContaining('Save failed'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget,
        reason: 'the screen must stay open for a retry');

    await unmount(tester);
  });
}

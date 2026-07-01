import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/services/database/database.dart'
    hide Item, Room;
import 'package:still_life/features/import/domain/import_review_args.dart';
import 'package:still_life/features/import/domain/import_review_item.dart';
import 'package:still_life/features/import/domain/parsed_import_item.dart';
import 'package:still_life/features/import/presentation/screens/import_review_screen.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/controllers/category_controller.dart';
import 'package:still_life/features/locations/domain/entities/room.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';
import 'package:still_life/services/import/import_fallback_seeder.dart';

import '../../../../test_setup.dart';

class _MockItemRepository extends Mock implements ItemRepository {}

class _MockImportFallbackSeeder extends Mock implements ImportFallbackSeeder {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Item(
        id: 'fallback',
        name: 'fallback',
        description: '',
        categoryId: 'c1',
        roomId: 'r1',
        isInsured: false,
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026),
      ),
    );
  });

  final testRoom = Room(
    id: 'r1',
    name: 'Kitchen',
    propertyId: 'p1',
    createdAt: DateTime(2026),
    modifiedAt: DateTime(2026),
  );

  final fakeItem = Item(
    id: 'item-1',
    name: 'Fake Item',
    description: '',
    categoryId: 'c1',
    roomId: 'r1',
    isInsured: false,
    createdAt: DateTime(2026),
    modifiedAt: DateTime(2026),
  );

  List<ImportReviewItem> makeItems([int count = 2]) => List.generate(
    count,
    (i) => ImportReviewItem(
      parsed: ParsedImportItem(
        name: 'Item $i',
        price: (i + 1) * 5.0,
        source: ImportSource.receipt,
      ),
    ),
  );

  Widget buildWidget(
    List<ImportReviewItem> items, {
    _MockItemRepository? repo,
    _MockImportFallbackSeeder? seeder,
    ImportReviewReceipt? receipt,
    AppDatabase? db,
  }) {
    final mockRepo = repo ?? _MockItemRepository();
    final mockSeeder = seeder ?? _MockImportFallbackSeeder();

    when(
      () => mockSeeder.ensureDefaults(),
    ).thenAnswer((_) async => ('cat-default', 'room-default'));
    when(
      () => mockRepo.createItem(any()),
    ).thenAnswer((_) async => Success(fakeItem));

    final router = GoRouter(
      initialLocation: '/review',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'review',
              builder: (_, _) =>
                  ImportReviewScreen(items: items, receipt: receipt),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        allRoomsProvider.overrideWith((ref) => Stream.value([testRoom])),
        categoriesProvider.overrideWith((ref) => Stream.value([])),
        itemRepositoryProvider.overrideWithValue(mockRepo),
        importFallbackSeederProvider.overrideWithValue(mockSeeder),
        if (db != null) databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('shows which engine parsed a receipt-sourced import', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      buildWidget(
        makeItems(),
        receipt: const ImportReviewReceipt(
          engineLabel: 'AI-structured (Cloud API)',
          ocrText: 'KROGER\nMilk 3.49',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('AI-structured (Cloud API)'), findsOneWidget);
  });

  testWidgets('shows no engine label for non-receipt imports', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(buildWidget(makeItems()));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('AI-structured'), findsNothing);
    expect(find.textContaining('Pattern-matched'), findsNothing);
  });

  testWidgets('shows LLM-written brand/model so the reviewer actually '
      'sees what will be persisted', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    final items = [
      ImportReviewItem(
        parsed: const ParsedImportItem(
          name: 'Laptop',
          price: 999.0,
          brand: 'Apple',
          model: 'MacBook Pro 16',
          source: ImportSource.receipt,
        ),
      ),
    ];
    await tester.pumpWidget(buildWidget(items));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Apple'), findsOneWidget,
        reason: 'persisted brand must be visible in review');
    expect(find.textContaining('MacBook Pro 16'), findsOneWidget,
        reason: 'persisted model must be visible in review');
  });

  testWidgets('shows item names and prices', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(buildWidget(makeItems()));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
  });

  testWidgets('Import FAB triggers createItem for accepted items', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    final mockRepo = _MockItemRepository();
    final mockSeeder = _MockImportFallbackSeeder();
    when(
      () => mockSeeder.ensureDefaults(),
    ).thenAnswer((_) async => ('cat-default', 'room-default'));
    when(
      () => mockRepo.createItem(any()),
    ).thenAnswer((_) async => Success(fakeItem));

    await tester.pumpWidget(
      buildWidget(makeItems(2), repo: mockRepo, seeder: mockSeeder),
    );
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 200));

    verify(() => mockRepo.createItem(any())).called(2);
  });

  testWidgets(
      'accepting a receipt-sourced import persists ONE receipt row '
      'and links every accepted item to it', (tester) async {
    ensureSqlite3();
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final mockRepo = _MockItemRepository();
    final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

    await tester.pumpWidget(
      buildWidget(
        makeItems(2),
        repo: mockRepo,
        db: db,
        receipt: ImportReviewReceipt(
          engineLabel: 'Pattern-matched',
          storeName: 'Kroger',
          purchaseDate: DateTime(2026, 7, 2),
          totalAmount: 16.48,
          ocrText: 'KROGER\nItem 0  5.00\nItem 1  10.00',
          imageBytes: imageBytes,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 200));

    // ONE Receipts row, carrying the receipt image + metadata; itemId
    // stays null (multi-item receipt — the link lives on Items).
    final receipts = await db.select(db.receipts).get();
    expect(receipts, hasLength(1));
    final receipt = receipts.single;
    expect(receipt.storeName, 'Kroger');
    expect(receipt.purchaseDate, DateTime(2026, 7, 2));
    expect(receipt.totalAmountCents, 1648);
    expect(receipt.ocrText, 'KROGER\nItem 0  5.00\nItem 1  10.00');
    expect(receipt.photoBytes, imageBytes);
    expect(receipt.itemId, isNull);

    // Every accepted item points at that row.
    final savedItems =
        verify(() => mockRepo.createItem(captureAny())).captured;
    expect(savedItems, hasLength(2));
    for (final item in savedItems.cast<Item>()) {
      expect(item.receiptId, receipt.id);
    }
  });

  testWidgets('a non-receipt import writes no receipt row', (tester) async {
    ensureSqlite3();
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final mockRepo = _MockItemRepository();

    await tester.pumpWidget(buildWidget(makeItems(1), repo: mockRepo, db: db));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 200));

    expect(await db.select(db.receipts).get(), isEmpty);
    final saved =
        verify(() => mockRepo.createItem(captureAny())).captured.cast<Item>();
    expect(saved.single.receiptId, isNull);
  });

  testWidgets('import persists brand/model/asin from the parsed item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    final mockRepo = _MockItemRepository();
    final items = [
      ImportReviewItem(
        parsed: ParsedImportItem(
          name: '55 inch TV',
          price: 499.99,
          purchaseDate: DateTime(2024, 4, 10),
          brand: 'Samsung',
          model: 'UN55TU7000',
          asin: 'B084JCFKQZ',
          source: ImportSource.receipt,
        ),
      ),
    ];

    await tester.pumpWidget(buildWidget(items, repo: mockRepo));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 200));

    final saved =
        verify(() => mockRepo.createItem(captureAny())).captured.cast<Item>();
    final item = saved.single;
    expect(item.brand, 'Samsung');
    expect(item.model, 'UN55TU7000');
    expect(item.asin, 'B084JCFKQZ');
    expect(item.purchaseDate, DateTime(2024, 4, 10));
    expect(item.purchasePriceCents, 49999);
  });

  testWidgets('import persists notes from the parsed item (Amazon Qty)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    final mockRepo = _MockItemRepository();
    final items = [
      ImportReviewItem(
        parsed: const ParsedImportItem(
          name: 'AA Batteries 12-pack',
          price: 12.99,
          notes: 'Qty: 3',
          source: ImportSource.amazonCsv,
        ),
      ),
    ];

    await tester.pumpWidget(buildWidget(items, repo: mockRepo));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 200));

    final saved =
        verify(() => mockRepo.createItem(captureAny())).captured.cast<Item>();
    expect(saved.single.notes, 'Qty: 3');
  });

  testWidgets('deselecting an item skips it on import', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    final mockRepo = _MockItemRepository();
    final mockSeeder = _MockImportFallbackSeeder();
    when(
      () => mockSeeder.ensureDefaults(),
    ).thenAnswer((_) async => ('cat-default', 'room-default'));
    when(
      () => mockRepo.createItem(any()),
    ).thenAnswer((_) async => Success(fakeItem));

    await tester.pumpWidget(
      buildWidget(makeItems(2), repo: mockRepo, seeder: mockSeeder),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Uncheck the first item
    final checkboxes = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .toList();
    await tester.tap(find.byWidget(checkboxes.first));
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 200));

    verify(() => mockRepo.createItem(any())).called(1);
  });

  testWidgets('a thrown import surfaces a snackbar and keeps the screen',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    final mockRepo = _MockItemRepository();
    final mockSeeder = _MockImportFallbackSeeder();

    await tester.pumpWidget(
      buildWidget(makeItems(1), repo: mockRepo, seeder: mockSeeder),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Re-stub AFTER buildWidget (which stubs a success default).
    when(() => mockSeeder.ensureDefaults())
        .thenThrow(StateError('database is locked'));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Import failed'), findsOneWidget);
    expect(find.byType(ImportReviewScreen), findsOneWidget,
        reason: 'no silent pop — the user retries from here');
  });
}

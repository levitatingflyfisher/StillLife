import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/import/domain/import_review_item.dart';
import 'package:still_life/features/import/domain/parsed_import_item.dart';
import 'package:still_life/features/import/presentation/screens/import_review_screen.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/controllers/category_controller.dart';
import 'package:still_life/features/locations/domain/entities/room.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';
import 'package:still_life/services/import/import_fallback_seeder.dart';

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
          builder: (_, __) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'review',
              builder: (_, __) => ImportReviewScreen(items: items),
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
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

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
}

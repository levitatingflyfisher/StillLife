import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/locations/domain/entities/storage_container.dart';
import 'package:still_life/features/locations/domain/repositories/container_repository.dart';
import 'package:still_life/features/locations/presentation/screens/container_detail_screen.dart';

class MockContainerRepository extends Mock implements ContainerRepository {}

class MockItemRepository extends Mock implements ItemRepository {}

StorageContainer _testContainer() {
  final now = DateTime(2025, 1, 1);
  return StorageContainer(
    id: 'container-1',
    roomId: 'room-1',
    name: 'Top Shelf',
    type: 'Shelf',
    createdAt: now,
    modifiedAt: now,
  );
}

Item _testItem(String id, String name) {
  final now = DateTime(2025, 1, 1);
  return Item(
    id: id,
    name: name,
    description: '',
    categoryId: 'cat-1',
    roomId: 'room-1',
    createdAt: now,
    modifiedAt: now,
  );
}

Widget buildSubject({
  required ContainerRepository containerRepo,
  required ItemRepository itemRepo,
  required String containerId,
}) {
  return ProviderScope(
    overrides: [
      containerRepositoryProvider.overrideWithValue(containerRepo),
      itemRepositoryProvider.overrideWithValue(itemRepo),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => ContainerDetailScreen(containerId: containerId),
          ),
        ],
      ),
    ),
  );
}

void main() {
  late MockContainerRepository mockContainerRepo;
  late MockItemRepository mockItemRepo;

  setUpAll(() {
    registerFallbackValue(const ItemQuery());
  });

  setUp(() {
    mockContainerRepo = MockContainerRepository();
    mockItemRepo = MockItemRepository();
  });

  group('ContainerDetailScreen', () {
    testWidgets('shows container name in app bar', (tester) async {
      final container = _testContainer();
      when(
        () => mockContainerRepo.getContainer(container.id),
      ).thenAnswer((_) async => Success(container));
      when(
        () => mockContainerRepo.watchContainer(container.id),
      ).thenAnswer((_) => Stream.value(container));
      when(
        () => mockItemRepo.watchItems(any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        buildSubject(
          containerRepo: mockContainerRepo,
          itemRepo: mockItemRepo,
          containerId: container.id,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Top Shelf'), findsOneWidget);
    });

    testWidgets('shows empty state when no items', (tester) async {
      final container = _testContainer();
      when(
        () => mockContainerRepo.getContainer(container.id),
      ).thenAnswer((_) async => Success(container));
      when(
        () => mockContainerRepo.watchContainer(container.id),
      ).thenAnswer((_) => Stream.value(container));
      when(
        () => mockItemRepo.watchItems(any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        buildSubject(
          containerRepo: mockContainerRepo,
          itemRepo: mockItemRepo,
          containerId: container.id,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('No items in this container'), findsOneWidget);
    });

    testWidgets('shows items when container has items', (tester) async {
      final container = _testContainer();
      final items = [
        _testItem('i1', 'Wrench Set'),
        _testItem('i2', 'Screwdriver'),
      ];
      when(
        () => mockContainerRepo.getContainer(container.id),
      ).thenAnswer((_) async => Success(container));
      when(
        () => mockContainerRepo.watchContainer(container.id),
      ).thenAnswer((_) => Stream.value(container));
      when(
        () => mockItemRepo.watchItems(any()),
      ).thenAnswer((_) => Stream.value(items));

      await tester.pumpWidget(
        buildSubject(
          containerRepo: mockContainerRepo,
          itemRepo: mockItemRepo,
          containerId: container.id,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Wrench Set'), findsOneWidget);
      expect(find.text('Screwdriver'), findsOneWidget);
    });

    testWidgets('shows label icon button', (tester) async {
      final container = _testContainer();
      when(
        () => mockContainerRepo.getContainer(container.id),
      ).thenAnswer((_) async => Success(container));
      when(
        () => mockContainerRepo.watchContainer(container.id),
      ).thenAnswer((_) => Stream.value(container));
      when(
        () => mockItemRepo.watchItems(any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        buildSubject(
          containerRepo: mockContainerRepo,
          itemRepo: mockItemRepo,
          containerId: container.id,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byIcon(Icons.qr_code_outlined), findsOneWidget);
    });
  });
}

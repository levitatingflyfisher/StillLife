import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:still_life/features/inventory/presentation/screens/inventory_screen.dart';

class MockItemRepository extends Mock implements ItemRepository {}

Item _makeItem(String id, String name) {
  final now = DateTime(2025, 1, 1);
  return Item(
    id: id,
    name: name,
    description: '',
    categoryId: 'c1',
    roomId: 'r1',
    createdAt: now,
    modifiedAt: now,
  );
}

Widget buildSubject(ItemRepository repo, List<Item> items) {
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(repo),
      inventoryItemsProvider.overrideWith((ref) => Stream.value(items)),
    ],
    child: const MaterialApp(home: InventoryScreen()),
  );
}

void main() {
  late MockItemRepository mockRepo;

  setUp(() {
    mockRepo = MockItemRepository();
  });

  group('InventoryScreen bulk operations', () {
    testWidgets('long-press enters selection mode', (tester) async {
      final items = [_makeItem('1', 'TV'), _makeItem('2', 'Lamp')];
      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping item in selection mode selects it', (tester) async {
      final items = [_makeItem('1', 'TV'), _makeItem('2', 'Lamp')];
      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      // Enter selection mode via long-press
      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      // Tap second item to select it
      await tester.tap(find.text('Lamp'));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('close button exits selection mode', (tester) async {
      final items = [_makeItem('1', 'TV')];
      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      final items = [_makeItem('1', 'TV')];
      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Items'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirming delete calls deleteItems on repository', (
      tester,
    ) async {
      final items = [_makeItem('1', 'TV')];
      when(
        () => mockRepo.deleteItems(any()),
      ).thenAnswer((_) async => const Success(null));

      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.deleteItems(['1'])).called(1);
    });

    testWidgets('delete failure shows snackbar and stays in selection mode', (
      tester,
    ) async {
      final items = [_makeItem('1', 'TV')];
      when(
        () => mockRepo.deleteItems(any()),
      ).thenAnswer((_) async => const Err(DatabaseFailure('disk full')));

      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Delete failed'), findsOneWidget);
      // Selection mode is preserved on failure so the user can retry.
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('FAB hidden in selection mode', (tester) async {
      final items = [_makeItem('1', 'TV')];
      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      // FAB visible before selection
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}

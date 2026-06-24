import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/search/presentation/screens/search_screen.dart';

class MockItemRepository extends Mock implements ItemRepository {}

Item _makeItem(String id, String name) {
  final now = DateTime(2025, 1, 1);
  return Item(
    id: id,
    name: name,
    description: '',
    categoryId: 'cat1',
    roomId: 'room1',
    createdAt: now,
    modifiedAt: now,
  );
}

Widget buildSubject(ItemRepository repo) {
  return ProviderScope(
    overrides: [itemRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: SearchScreen()),
  );
}

void main() {
  late MockItemRepository mockRepo;

  setUp(() {
    mockRepo = MockItemRepository();
  });

  group('SearchScreen', () {
    testWidgets('shows empty prompt when query is blank', (tester) async {
      await tester.pumpWidget(buildSubject(mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Type to search all items'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows results after entering a query', (tester) async {
      final items = [
        _makeItem('1', 'Samsung TV'),
        _makeItem('2', 'Samsung Soundbar'),
      ];
      when(
        () => mockRepo.searchItems('Samsung'),
      ).thenAnswer((_) => Stream.value(items));

      await tester.pumpWidget(buildSubject(mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Samsung');
      await tester.pumpAndSettle();

      expect(find.text('Samsung TV'), findsOneWidget);
      expect(find.text('Samsung Soundbar'), findsOneWidget);
    });

    testWidgets('shows no-results message when stream is empty', (
      tester,
    ) async {
      when(
        () => mockRepo.searchItems(any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildSubject(mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'unicorn');
      await tester.pumpAndSettle();

      expect(find.textContaining('No results for'), findsOneWidget);
    });

    testWidgets('clear button resets to empty prompt', (tester) async {
      when(
        () => mockRepo.searchItems(any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildSubject(mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pumpAndSettle();

      // Close (X) button should appear
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Type to search all items'), findsOneWidget);
    });
  });
}

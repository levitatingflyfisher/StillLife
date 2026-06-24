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

void main() {
  testWidgets(
      'search results do not overflow at 320dp / textScale 3.0',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockItemRepository();
    when(() => mockRepo.searchItems(any())).thenAnswer(
      (_) => Stream.value([
        _makeItem('1', 'Samsung TV'),
        _makeItem('2', 'Samsung Soundbar'),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemRepositoryProvider.overrideWithValue(mockRepo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(3.0)),
              child: const SearchScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Samsung');
    await tester.pumpAndSettle();

    // The results view (Save-search action + list) must not overflow on a
    // narrow screen at max accessibility text scale.
    expect(tester.takeException(), isNull);
  });
}

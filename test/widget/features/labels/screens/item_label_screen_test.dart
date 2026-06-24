import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/labels/presentation/screens/item_label_screen.dart';

class MockItemRepository extends Mock implements ItemRepository {}

Item _testItem() {
  final now = DateTime(2025, 1, 1);
  return Item(
    id: 'abc12345-0000-0000-0000-000000000000',
    name: 'Samsung 4K TV',
    description: '',
    categoryId: 'c1',
    roomId: 'r1',
    roomName: 'Living Room',
    createdAt: now,
    modifiedAt: now,
  );
}

Widget buildSubject(ItemRepository repo, Item item) {
  return ProviderScope(
    overrides: [itemRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(home: ItemLabelScreen(itemId: item.id)),
  );
}

void main() {
  late MockItemRepository mockRepo;

  setUp(() {
    mockRepo = MockItemRepository();
  });

  group('ItemLabelScreen', () {
    testWidgets('shows item name on label', (tester) async {
      final item = _testItem();
      when(
        () => mockRepo.getItem(item.id),
      ).thenAnswer((_) async => Success(item));
      when(
        () => mockRepo.watchItem(item.id),
      ).thenAnswer((_) => Stream.value(item));

      await tester.pumpWidget(buildSubject(mockRepo, item));
      await tester.pumpAndSettle();

      expect(find.text('Samsung 4K TV'), findsOneWidget);
    });

    testWidgets('shows room name on label', (tester) async {
      final item = _testItem();
      when(
        () => mockRepo.getItem(item.id),
      ).thenAnswer((_) async => Success(item));
      when(
        () => mockRepo.watchItem(item.id),
      ).thenAnswer((_) => Stream.value(item));

      await tester.pumpWidget(buildSubject(mockRepo, item));
      await tester.pumpAndSettle();

      expect(find.text('Living Room'), findsOneWidget);
    });

    testWidgets('shows QR code widget', (tester) async {
      final item = _testItem();
      when(
        () => mockRepo.getItem(item.id),
      ).thenAnswer((_) async => Success(item));
      when(
        () => mockRepo.watchItem(item.id),
      ).thenAnswer((_) => Stream.value(item));

      await tester.pumpWidget(buildSubject(mockRepo, item));
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('shows share button', (tester) async {
      final item = _testItem();
      when(
        () => mockRepo.getItem(item.id),
      ).thenAnswer((_) async => Success(item));
      when(
        () => mockRepo.watchItem(item.id),
      ).thenAnswer((_) => Stream.value(item));

      await tester.pumpWidget(buildSubject(mockRepo, item));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets('shows human-readable label ID', (tester) async {
      final item = _testItem();
      when(
        () => mockRepo.getItem(item.id),
      ).thenAnswer((_) async => Success(item));
      when(
        () => mockRepo.watchItem(item.id),
      ).thenAnswer((_) => Stream.value(item));

      await tester.pumpWidget(buildSubject(mockRepo, item));
      await tester.pumpAndSettle();

      // Label ID is three words separated by hyphens
      final labelFinder = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data ?? '').split('-').length == 3 &&
            RegExp(r'^[a-z]+-[a-z]+-[a-z]+$').hasMatch(w.data ?? ''),
      );
      expect(labelFinder, findsOneWidget);
    });
  });
}

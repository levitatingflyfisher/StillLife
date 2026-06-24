import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/labels/presentation/screens/container_label_screen.dart';
import 'package:still_life/features/locations/domain/entities/storage_container.dart';
import 'package:still_life/features/locations/domain/repositories/container_repository.dart';

class MockContainerRepository extends Mock implements ContainerRepository {}

StorageContainer _testContainer() {
  final now = DateTime(2025, 1, 1);
  return StorageContainer(
    id: 'abc12345-0000-0000-0000-000000000001',
    roomId: 'r1',
    name: 'Top Shelf',
    type: 'Shelf',
    createdAt: now,
    modifiedAt: now,
  );
}

Widget buildSubject(ContainerRepository repo, StorageContainer container) {
  return ProviderScope(
    overrides: [containerRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(home: ContainerLabelScreen(containerId: container.id)),
  );
}

void main() {
  late MockContainerRepository mockRepo;

  setUp(() {
    mockRepo = MockContainerRepository();
  });

  group('ContainerLabelScreen', () {
    testWidgets('shows container name on label', (tester) async {
      final container = _testContainer();
      when(
        () => mockRepo.getContainer(container.id),
      ).thenAnswer((_) async => Success(container));
      when(
        () => mockRepo.watchContainer(container.id),
      ).thenAnswer((_) => Stream.value(container));

      await tester.pumpWidget(buildSubject(mockRepo, container));
      await tester.pumpAndSettle();

      expect(find.text('Top Shelf'), findsOneWidget);
    });

    testWidgets('shows QR code widget', (tester) async {
      final container = _testContainer();
      when(
        () => mockRepo.getContainer(container.id),
      ).thenAnswer((_) async => Success(container));
      when(
        () => mockRepo.watchContainer(container.id),
      ).thenAnswer((_) => Stream.value(container));

      await tester.pumpWidget(buildSubject(mockRepo, container));
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('shows share button', (tester) async {
      final container = _testContainer();
      when(
        () => mockRepo.getContainer(container.id),
      ).thenAnswer((_) async => Success(container));
      when(
        () => mockRepo.watchContainer(container.id),
      ).thenAnswer((_) => Stream.value(container));

      await tester.pumpWidget(buildSubject(mockRepo, container));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets('shows human-readable label ID', (tester) async {
      final container = _testContainer();
      when(
        () => mockRepo.getContainer(container.id),
      ).thenAnswer((_) async => Success(container));
      when(
        () => mockRepo.watchContainer(container.id),
      ).thenAnswer((_) => Stream.value(container));

      await tester.pumpWidget(buildSubject(mockRepo, container));
      await tester.pumpAndSettle();

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

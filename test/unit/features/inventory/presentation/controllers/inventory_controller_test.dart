import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/controllers/inventory_controller.dart';

class _MockRepo extends Mock implements ItemRepository {}

Item _item({String id = 'i1'}) => Item(
  id: id,
  name: 'Chair',
  description: '',
  categoryId: 'c1',
  roomId: 'r1',
  isInsured: false,
  createdAt: DateTime(2026),
  modifiedAt: DateTime(2026),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_item());
  });

  ProviderContainer makeContainer(ItemRepository repo) {
    return ProviderContainer(
      overrides: [itemRepositoryProvider.overrideWithValue(repo)],
    );
  }

  test(
    'itemControllerProvider is an AsyncNotifierProvider with AsyncData(null) initial state',
    () async {
      final repo = _MockRepo();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(itemControllerProvider.future);
      final state = container.read(itemControllerProvider);
      expect(state, isA<AsyncData<void>>());
    },
  );

  test('createItem sets AsyncData on success', () async {
    final repo = _MockRepo();
    when(
      () => repo.createItem(any()),
    ).thenAnswer((_) async => Success(_item()));
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    await container.read(itemControllerProvider.future);
    final controller = container.read(itemControllerProvider.notifier);
    final ok = await controller.createItem(_item());
    expect(ok, isTrue);
    expect(container.read(itemControllerProvider), isA<AsyncData<void>>());
  });

  test('createItem sets AsyncError on failure', () async {
    final repo = _MockRepo();
    when(
      () => repo.createItem(any()),
    ).thenAnswer((_) async => const Err<Item>(DatabaseFailure('boom')));
    final container = makeContainer(repo);
    addTearDown(container.dispose);

    await container.read(itemControllerProvider.future);
    final controller = container.read(itemControllerProvider.notifier);
    final ok = await controller.createItem(_item());
    expect(ok, isFalse);
    expect(container.read(itemControllerProvider), isA<AsyncError<void>>());
  });

  test(
    'updateItem/deleteItem/moveItems preserve original signatures',
    () async {
      final repo = _MockRepo();
      when(
        () => repo.updateItem(any()),
      ).thenAnswer((_) async => Success(_item()));
      when(
        () => repo.deleteItem(any()),
      ).thenAnswer((_) async => const Success<void>(null));
      when(
        () => repo.moveItems(any(), any()),
      ).thenAnswer((_) async => const Success<void>(null));
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(itemControllerProvider.future);
      final controller = container.read(itemControllerProvider.notifier);
      expect(await controller.updateItem(_item()), isTrue);
      expect(await controller.deleteItem('i1'), isTrue);
      expect(await controller.moveItems(const ['i1'], 'r2'), isTrue);
    },
  );
}

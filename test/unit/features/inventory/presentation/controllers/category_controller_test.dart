import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/category.dart';
import 'package:still_life/features/inventory/domain/repositories/category_repository.dart';
import 'package:still_life/features/inventory/presentation/controllers/category_controller.dart';

class _MockRepo extends Mock implements CategoryRepository {}

Category _cat() => Category(
  id: 'c1',
  name: 'Electronics',
  createdAt: DateTime(2026),
  modifiedAt: DateTime(2026),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_cat());
  });

  ProviderContainer makeContainer(CategoryRepository repo) {
    return ProviderContainer(
      overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
    );
  }

  test(
    'categoryControllerProvider is AsyncNotifier with AsyncData(null) initial state',
    () async {
      final container = makeContainer(_MockRepo());
      addTearDown(container.dispose);
      await container.read(categoryControllerProvider.future);
      expect(
        container.read(categoryControllerProvider),
        isA<AsyncData<void>>(),
      );
    },
  );

  test('createCategory success sets AsyncData and returns true', () async {
    final repo = _MockRepo();
    when(
      () => repo.createCategory(any()),
    ).thenAnswer((_) async => Success(_cat()));
    final container = makeContainer(repo);
    addTearDown(container.dispose);
    await container.read(categoryControllerProvider.future);

    final ok = await container
        .read(categoryControllerProvider.notifier)
        .createCategory(_cat());
    expect(ok, isTrue);
    expect(container.read(categoryControllerProvider), isA<AsyncData<void>>());
  });

  test('createCategory failure sets AsyncError and returns false', () async {
    final repo = _MockRepo();
    when(
      () => repo.createCategory(any()),
    ).thenAnswer((_) async => const Err<Category>(DatabaseFailure('boom')));
    final container = makeContainer(repo);
    addTearDown(container.dispose);
    await container.read(categoryControllerProvider.future);

    final ok = await container
        .read(categoryControllerProvider.notifier)
        .createCategory(_cat());
    expect(ok, isFalse);
    expect(container.read(categoryControllerProvider), isA<AsyncError<void>>());
  });

  test(
    'updateCategory / deleteCategory / seedDefaults keep signatures',
    () async {
      final repo = _MockRepo();
      when(
        () => repo.updateCategory(any()),
      ).thenAnswer((_) async => Success(_cat()));
      when(
        () => repo.deleteCategory(any()),
      ).thenAnswer((_) async => const Success<void>(null));
      when(
        () => repo.seedDefaults(),
      ).thenAnswer((_) async => const Success<void>(null));
      final container = makeContainer(repo);
      addTearDown(container.dispose);
      await container.read(categoryControllerProvider.future);
      final ctrl = container.read(categoryControllerProvider.notifier);
      expect(await ctrl.updateCategory(_cat()), isTrue);
      expect(await ctrl.deleteCategory('c1'), isTrue);
      expect(await ctrl.seedDefaults(), isTrue);
    },
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/locations/domain/entities/property.dart';
import 'package:still_life/features/locations/domain/entities/room.dart';
import 'package:still_life/features/locations/domain/entities/storage_container.dart';
import 'package:still_life/features/locations/domain/repositories/container_repository.dart';
import 'package:still_life/features/locations/domain/repositories/property_repository.dart';
import 'package:still_life/features/locations/domain/repositories/room_repository.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';

class _MockPropertyRepo extends Mock implements PropertyRepository {}

class _MockRoomRepo extends Mock implements RoomRepository {}

class _MockContainerRepo extends Mock implements ContainerRepository {}

Property _prop() => Property(
  id: 'p1',
  name: 'Home',
  createdAt: DateTime(2026),
  modifiedAt: DateTime(2026),
);

Room _room() => Room(
  id: 'r1',
  propertyId: 'p1',
  name: 'Kitchen',
  createdAt: DateTime(2026),
  modifiedAt: DateTime(2026),
);

StorageContainer _container() => StorageContainer(
  id: 'c1',
  roomId: 'r1',
  name: 'Box A',
  createdAt: DateTime(2026),
  modifiedAt: DateTime(2026),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_prop());
    registerFallbackValue(_room());
    registerFallbackValue(_container());
  });

  group('PropertyController', () {
    test('is AsyncNotifier with AsyncData(null) initial state', () async {
      final container = ProviderContainer(
        overrides: [
          propertyRepositoryProvider.overrideWithValue(_MockPropertyRepo()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(propertyControllerProvider.future);
      expect(
        container.read(propertyControllerProvider),
        isA<AsyncData<void>>(),
      );
    });

    test('createProperty success returns true', () async {
      final repo = _MockPropertyRepo();
      when(
        () => repo.createProperty(any()),
      ).thenAnswer((_) async => Success(_prop()));
      final container = ProviderContainer(
        overrides: [propertyRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(propertyControllerProvider.future);
      final ok = await container
          .read(propertyControllerProvider.notifier)
          .createProperty(_prop());
      expect(ok, isTrue);
      expect(
        container.read(propertyControllerProvider),
        isA<AsyncData<void>>(),
      );
    });

    test('createProperty failure returns false', () async {
      final repo = _MockPropertyRepo();
      when(
        () => repo.createProperty(any()),
      ).thenAnswer((_) async => const Err<Property>(DatabaseFailure('boom')));
      final container = ProviderContainer(
        overrides: [propertyRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(propertyControllerProvider.future);
      final ok = await container
          .read(propertyControllerProvider.notifier)
          .createProperty(_prop());
      expect(ok, isFalse);
      expect(
        container.read(propertyControllerProvider),
        isA<AsyncError<void>>(),
      );
    });
  });

  group('RoomController', () {
    test('createRoom / updateRoom / deleteRoom / seedDefaults', () async {
      final repo = _MockRoomRepo();
      when(
        () => repo.createRoom(any()),
      ).thenAnswer((_) async => Success(_room()));
      when(
        () => repo.updateRoom(any()),
      ).thenAnswer((_) async => Success(_room()));
      when(
        () => repo.deleteRoom(any()),
      ).thenAnswer((_) async => const Success<void>(null));
      when(
        () => repo.seedDefaults(any()),
      ).thenAnswer((_) async => const Success<void>(null));
      final container = ProviderContainer(
        overrides: [roomRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(roomControllerProvider.future);
      final ctrl = container.read(roomControllerProvider.notifier);
      expect(await ctrl.createRoom(_room()), isTrue);
      expect(await ctrl.updateRoom(_room()), isTrue);
      expect(await ctrl.deleteRoom('r1'), isTrue);
      expect(await ctrl.seedDefaults('p1'), isTrue);
    });
  });

  group('ContainerController', () {
    test('create / delete', () async {
      final repo = _MockContainerRepo();
      when(
        () => repo.createContainer(any()),
      ).thenAnswer((_) async => Success(_container()));
      when(
        () => repo.deleteContainer(any()),
      ).thenAnswer((_) async => const Success<void>(null));
      final container = ProviderContainer(
        overrides: [containerRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(containerControllerProvider.future);
      final ctrl = container.read(containerControllerProvider.notifier);
      expect(await ctrl.create(_container()), isTrue);
      expect(await ctrl.delete('c1'), isTrue);
    });
  });
}

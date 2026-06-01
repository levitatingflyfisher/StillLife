import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/storage_container.dart';
import '../../domain/repositories/container_repository.dart';
import '../../domain/repositories/property_repository.dart';
import '../../domain/repositories/room_repository.dart';

/// All properties.
final propertiesProvider = StreamProvider<List<Property>>((ref) {
  return ref.watch(propertyRepositoryProvider).watchProperties();
});

/// Currently selected property ID.
final selectedPropertyIdProvider = StateProvider<String?>((ref) => null);

/// Rooms for the selected property (or all rooms if no property selected).
final roomsProvider = StreamProvider<List<Room>>((ref) {
  final propertyId = ref.watch(selectedPropertyIdProvider);
  return ref.watch(roomRepositoryProvider).watchRooms(propertyId: propertyId);
});

/// Watches all rooms across all properties (used by import review screen).
final allRoomsProvider = StreamProvider<List<Room>>((ref) {
  return ref.watch(roomRepositoryProvider).watchRooms(propertyId: null);
});

/// Property CRUD controller.
final propertyControllerProvider =
    AsyncNotifierProvider<PropertyController, void>(PropertyController.new);

class PropertyController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  PropertyRepository get _repo => ref.read(propertyRepositoryProvider);

  Future<bool> createProperty(Property property) async {
    state = const AsyncLoading();
    final result = await _repo.createProperty(property);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> updateProperty(Property property) async {
    state = const AsyncLoading();
    final result = await _repo.updateProperty(property);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> deleteProperty(String id) async {
    state = const AsyncLoading();
    final result = await _repo.deleteProperty(id);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

/// Room CRUD controller.
final roomControllerProvider = AsyncNotifierProvider<RoomController, void>(
  RoomController.new,
);

class RoomController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  RoomRepository get _repo => ref.read(roomRepositoryProvider);

  Future<bool> createRoom(Room room) async {
    state = const AsyncLoading();
    final result = await _repo.createRoom(room);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> updateRoom(Room room) async {
    state = const AsyncLoading();
    final result = await _repo.updateRoom(room);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> deleteRoom(String id) async {
    state = const AsyncLoading();
    final result = await _repo.deleteRoom(id);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> seedDefaults(String propertyId) async {
    state = const AsyncLoading();
    final result = await _repo.seedDefaults(propertyId);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

/// Containers within a specific room.
final containersInRoomProvider =
    StreamProvider.family<List<StorageContainer>, String>((ref, roomId) {
      return ref
          .watch(containerRepositoryProvider)
          .watchContainers(roomId: roomId);
    });

/// All containers across all rooms.
final allContainersProvider = StreamProvider<List<StorageContainer>>((ref) {
  return ref.watch(containerRepositoryProvider).watchAllContainers();
});

/// Container CRUD controller.
final containerControllerProvider =
    AsyncNotifierProvider<ContainerController, void>(ContainerController.new);

class ContainerController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  ContainerRepository get _repo => ref.read(containerRepositoryProvider);

  Future<bool> create(StorageContainer container) async {
    state = const AsyncLoading();
    final result = await _repo.createContainer(container);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> delete(String id) async {
    state = const AsyncLoading();
    final result = await _repo.deleteContainer(id);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

/// Single room detail provider — streams so the screen refreshes after
/// edits or item count changes.
final roomDetailProvider = StreamProvider.family<Room?, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).watchRoom(roomId);
});

/// Single container detail provider — streams so the screen refreshes after
/// edits or container changes.
final containerDetailProvider =
    StreamProvider.family<StorageContainer?, String>((ref, containerId) {
      return ref.watch(containerRepositoryProvider).watchContainer(containerId);
    });

import '../../../../core/errors/result.dart';
import '../entities/room.dart';

abstract class RoomRepository {
  Stream<List<Room>> watchRooms({String? propertyId});
  Future<Result<Room>> getRoom(String id);
  Stream<Room?> watchRoom(String id);
  Future<Result<Room>> createRoom(Room room);
  Future<Result<Room>> updateRoom(Room room);
  Future<Result<void>> deleteRoom(String id);
  Future<Result<void>> reorderRooms(List<String> roomIdsInOrder);
  Future<Result<void>> seedDefaults(String propertyId);
}

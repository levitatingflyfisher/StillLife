import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';

const _uuid = Uuid();

class RoomRepositoryImpl implements RoomRepository {
  final db.AppDatabase _db;

  RoomRepositoryImpl(this._db);

  @override
  Stream<List<Room>> watchRooms({String? propertyId}) {
    return _db.locationDao.watchAllRooms(propertyId: propertyId).asyncMap((
      rows,
    ) async {
      final counts = await _db.locationDao.getRoomItemCounts();
      final values = await _db.locationDao.getRoomValues();
      return rows.map((r) => _mapToEntity(r, counts, values)).toList();
    });
  }

  @override
  Stream<Room?> watchRoom(String id) {
    final query = _db.select(_db.rooms)
      ..where((t) => t.id.equals(id) & t.isDeleted.equals(false));
    return query.watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      final counts = await _db.locationDao.getRoomItemCounts();
      final values = await _db.locationDao.getRoomValues();
      return _mapToEntity(row, counts, values);
    });
  }

  @override
  Future<Result<Room>> getRoom(String id) async {
    try {
      final row = await _db.locationDao.getRoomById(id);
      if (row == null) {
        return const Err(DatabaseFailure('Room not found'));
      }
      final counts = await _db.locationDao.getRoomItemCounts();
      final values = await _db.locationDao.getRoomValues();
      return Success(_mapToEntity(row, counts, values));
    } catch (e) {
      return Err(DatabaseFailure('Failed to get room: $e'));
    }
  }

  @override
  Future<Result<Room>> createRoom(Room room) async {
    try {
      final now = DateTime.now();
      final id = room.id.isEmpty ? _uuid.v4() : room.id;
      final companion = db.RoomsCompanion.insert(
        id: id,
        propertyId: room.propertyId,
        parentId: Value(room.parentId),
        name: room.name,
        floor: Value(room.floor),
        sortOrder: Value(room.sortOrder),
        photoPath: Value(room.photoPath),
        createdAt: now,
        modifiedAt: now,
      );
      await _db.locationDao.insertRoom(companion);
      return getRoom(id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to create room: $e'));
    }
  }

  @override
  Future<Result<Room>> updateRoom(Room room) async {
    try {
      final companion = db.RoomsCompanion(
        id: Value(room.id),
        propertyId: Value(room.propertyId),
        parentId: Value(room.parentId),
        name: Value(room.name),
        floor: Value(room.floor),
        sortOrder: Value(room.sortOrder),
        photoPath: Value(room.photoPath),
        modifiedAt: Value(DateTime.now()),
      );
      await _db.locationDao.updateRoom(companion);
      return getRoom(room.id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to update room: $e'));
    }
  }

  @override
  Future<Result<void>> deleteRoom(String id) async {
    try {
      await _db.locationDao.deleteRoom(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete room: $e'));
    }
  }

  @override
  Future<Result<void>> reorderRooms(List<String> roomIdsInOrder) async {
    try {
      await _db.locationDao.reorderRooms(roomIdsInOrder);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to reorder rooms: $e'));
    }
  }

  @override
  Future<Result<void>> seedDefaults(String propertyId) async {
    try {
      final now = DateTime.now();
      final defaultRooms = [
        AppConstants.unsortedRoom,
        AppConstants.personalCarry,
        AppConstants.vehicle,
        AppConstants.storageUnit,
      ];
      final companions = defaultRooms.asMap().entries.map((entry) {
        return db.RoomsCompanion.insert(
          id: _uuid.v4(),
          propertyId: propertyId,
          name: entry.value,
          sortOrder: Value(entry.key),
          createdAt: now,
          modifiedAt: now,
        );
      }).toList();
      await _db.locationDao.seedDefaultRooms(propertyId, companions);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to seed default rooms: $e'));
    }
  }

  Room _mapToEntity(
    db.Room row,
    Map<String, int> counts,
    Map<String, double> values,
  ) {
    return Room(
      id: row.id,
      propertyId: row.propertyId,
      parentId: row.parentId,
      name: row.name,
      floor: row.floor,
      sortOrder: row.sortOrder,
      photoPath: row.photoPath,
      createdAt: row.createdAt,
      modifiedAt: row.modifiedAt,
      itemCount: counts[row.id] ?? 0,
      totalValue: values[row.id] ?? 0.0,
    );
  }
}

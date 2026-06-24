import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../domain/entities/storage_container.dart';
import '../../domain/repositories/container_repository.dart';

const _uuid = Uuid();

class ContainerRepositoryImpl implements ContainerRepository {
  final db.AppDatabase _db;

  ContainerRepositoryImpl(this._db);

  @override
  Stream<List<StorageContainer>> watchContainers({required String roomId}) {
    return _db.containerDao
        .watchByRoom(roomId)
        .map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<List<StorageContainer>> watchAllContainers() {
    return _db.containerDao.watchAll().map((rows) => rows.map(_map).toList());
  }

  @override
  Stream<StorageContainer?> watchContainer(String id) {
    final query = _db.select(_db.storageContainers)
      ..where((t) => t.id.equals(id) & t.isDeleted.equals(false));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _map(row),
    );
  }

  @override
  Future<Result<StorageContainer>> getContainer(String id) async {
    try {
      final row = await _db.containerDao.getById(id);
      if (row == null) {
        return const Err(DatabaseFailure('Container not found'));
      }
      return Success(_map(row));
    } catch (e) {
      return Err(DatabaseFailure('Failed to get container: $e'));
    }
  }

  @override
  Future<Result<StorageContainer>> createContainer(
    StorageContainer container,
  ) async {
    try {
      final now = DateTime.now();
      final id = container.id.isEmpty ? _uuid.v4() : container.id;
      await _db.containerDao.insert(
        db.StorageContainersCompanion.insert(
          id: id,
          roomId: container.roomId,
          name: container.name,
          type: Value(container.type),
          createdAt: now,
          modifiedAt: now,
        ),
      );
      final row = await _db.containerDao.getById(id);
      if (row == null) {
        return const Err(DatabaseFailure('Container not found after insert'));
      }
      return Success(_map(row));
    } catch (e) {
      return Err(DatabaseFailure('Failed to create container: $e'));
    }
  }

  @override
  Future<Result<void>> deleteContainer(String id) async {
    try {
      await _db.containerDao.softDelete(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete container: $e'));
    }
  }

  StorageContainer _map(db.StorageContainer row) => StorageContainer(
    id: row.id,
    roomId: row.roomId,
    name: row.name,
    type: row.type,
    createdAt: row.createdAt,
    modifiedAt: row.modifiedAt,
  );
}

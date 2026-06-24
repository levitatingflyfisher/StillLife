import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db_pkg;
import '../../domain/entities/maintenance_log.dart';
import '../../domain/repositories/maintenance_repository.dart';

const _uuid = Uuid();

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final db_pkg.AppDatabase _db;

  MaintenanceRepositoryImpl(this._db);

  @override
  Stream<List<MaintenanceLog>> watchAll() {
    return _db.maintenanceDao.watchAll().map(
      (rows) => rows.map(_toEntity).toList(),
    );
  }

  @override
  Stream<List<MaintenanceLog>> watchByItem(String itemId) {
    return _db.maintenanceDao
        .watchByItem(itemId)
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Result<List<MaintenanceLog>>> getUpcoming() async {
    try {
      final rows = await _db.maintenanceDao.getUpcoming();
      return Success(rows.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure('Failed to get upcoming maintenance: $e'));
    }
  }

  @override
  Future<Result<MaintenanceLog>> create(MaintenanceLog log) async {
    try {
      final now = DateTime.now();
      final id = log.id.isEmpty ? _uuid.v4() : log.id;
      await _db.maintenanceDao.insertLog(
        db_pkg.MaintenanceLogsCompanion.insert(
          id: id,
          itemId: Value(log.itemId),
          propertyId: Value(log.propertyId),
          title: log.title,
          description: Value(log.description),
          cost: Value(log.cost),
          performedAt: log.performedAt,
          nextDueAt: Value(log.nextDueAt),
          servicedBy: Value(log.servicedBy),
          createdAt: now,
          modifiedAt: now,
        ),
      );
      final created = await _db.maintenanceDao.getById(id);
      return Success(_toEntity(created!));
    } catch (e) {
      return Err(DatabaseFailure('Failed to create maintenance log: $e'));
    }
  }

  @override
  Future<Result<MaintenanceLog>> update(MaintenanceLog log) async {
    try {
      final now = DateTime.now();
      final ok = await _db.maintenanceDao.updateLog(
        db_pkg.MaintenanceLogsCompanion(
          id: Value(log.id),
          itemId: Value(log.itemId),
          propertyId: Value(log.propertyId),
          title: Value(log.title),
          description: Value(log.description),
          cost: Value(log.cost),
          performedAt: Value(log.performedAt),
          nextDueAt: Value(log.nextDueAt),
          servicedBy: Value(log.servicedBy),
          modifiedAt: Value(now),
        ),
      );
      if (!ok) return const Err(DatabaseFailure('Maintenance log not found'));
      final updated = await _db.maintenanceDao.getById(log.id);
      return Success(_toEntity(updated!));
    } catch (e) {
      return Err(DatabaseFailure('Failed to update maintenance log: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _db.maintenanceDao.deleteLog(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete maintenance log: $e'));
    }
  }

  MaintenanceLog _toEntity(db_pkg.MaintenanceLog row) => MaintenanceLog(
    id: row.id,
    itemId: row.itemId,
    propertyId: row.propertyId,
    title: row.title,
    description: row.description,
    cost: row.cost,
    performedAt: row.performedAt,
    nextDueAt: row.nextDueAt,
    servicedBy: row.servicedBy,
    createdAt: row.createdAt,
    modifiedAt: row.modifiedAt,
  );
}

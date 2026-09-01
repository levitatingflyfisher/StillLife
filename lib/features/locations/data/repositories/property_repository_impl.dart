import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../../../../core/sync/sync_stamp.dart';

const _uuid = Uuid();

class PropertyRepositoryImpl implements PropertyRepository {
  final db.AppDatabase _db;

  PropertyRepositoryImpl(this._db, {SyncStamp stamp = SyncStamp.none})
    : _stamp = stamp;

  /// Gives every write its sync stamp (see [SyncStamp]).
  final SyncStamp _stamp;

  @override
  Stream<List<Property>> watchProperties() {
    return _db.locationDao.watchAllProperties().map(
      (rows) => rows.map(_mapToEntity).toList(),
    );
  }

  @override
  Future<Result<Property>> getProperty(String id) async {
    try {
      final row = await _db.locationDao.getPropertyById(id);
      if (row == null) {
        return const Err(DatabaseFailure('Property not found'));
      }
      return Success(_mapToEntity(row));
    } catch (e) {
      return Err(DatabaseFailure('Failed to get property: $e'));
    }
  }

  @override
  Future<Result<Property>> createProperty(Property property) async {
    try {
      final now = DateTime.now();
      final id = property.id.isEmpty ? _uuid.v4() : property.id;
      final companion = db.PropertiesCompanion.insert(
        id: id,
        name: property.name,
        address: Value(property.address),
        type: Value(property.type.label),
        createdAt: now,
        modifiedAt: now,
      );
      await _stamp.write(
        (c) => _db.locationDao.insertProperty(companion, crdt: c),
      );
      return getProperty(id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to create property: $e'));
    }
  }

  @override
  Future<Result<Property>> updateProperty(Property property) async {
    try {
      final companion = db.PropertiesCompanion(
        id: Value(property.id),
        name: Value(property.name),
        address: Value(property.address),
        type: Value(property.type.label),
        modifiedAt: Value(DateTime.now()),
      );
      await _stamp.write(
        (c) => _db.locationDao.updateProperty(companion, crdt: c),
      );
      return getProperty(property.id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to update property: $e'));
    }
  }

  @override
  Future<Result<void>> deleteProperty(String id) async {
    try {
      await _stamp.write((c) => _db.locationDao.deleteProperty(id, crdt: c));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete property: $e'));
    }
  }

  Property _mapToEntity(db.Property row) {
    return Property(
      id: row.id,
      name: row.name,
      address: row.address,
      type: PropertyType.fromString(row.type),
      createdAt: row.createdAt,
      modifiedAt: row.modifiedAt,
    );
  }
}

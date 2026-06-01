import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';

const _uuid = Uuid();

class PhotoRepositoryImpl implements PhotoRepository {
  final db.AppDatabase _db;

  PhotoRepositoryImpl(this._db);

  @override
  Stream<List<Photo>> watchItemPhotos(String itemId) {
    return _db.photoDao
        .watchItemPhotos(itemId)
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<Result<Photo>> addPhoto(Photo photo) async {
    try {
      final now = DateTime.now();
      final id = photo.id.isEmpty ? _uuid.v4() : photo.id;
      final companion = db.PhotosCompanion.insert(
        id: id,
        itemId: photo.itemId,
        filePath: photo.filePath,
        isPrimary: Value(photo.isPrimary),
        source: Value(photo.source.name),
        capturedAt: photo.capturedAt,
        createdAt: now,
        modifiedAt: now,
      );
      await _db.photoDao.insertPhoto(companion);
      final row = await _db.photoDao.getPhotoById(id);
      if (row == null) {
        return const Err(DatabaseFailure('Photo not found after insert'));
      }
      return Success(_mapToEntity(row));
    } catch (e) {
      return Err(DatabaseFailure('Failed to add photo: $e'));
    }
  }

  @override
  Future<Result<void>> deletePhoto(String id) async {
    try {
      await _db.photoDao.deletePhoto(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete photo: $e'));
    }
  }

  @override
  Future<Result<void>> setPrimaryPhoto(String itemId, String photoId) async {
    try {
      await _db.photoDao.setPrimaryPhoto(itemId, photoId);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to set primary photo: $e'));
    }
  }

  @override
  Future<Result<Photo?>> getPrimaryPhoto(String itemId) async {
    try {
      final row = await _db.photoDao.getPrimaryPhoto(itemId);
      return Success(row != null ? _mapToEntity(row) : null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to get primary photo: $e'));
    }
  }

  Photo _mapToEntity(db.Photo row) {
    return Photo(
      id: row.id,
      itemId: row.itemId,
      filePath: row.filePath,
      isPrimary: row.isPrimary,
      source: PhotoSource.values.firstWhere(
        (e) => e.name == row.source,
        orElse: () => PhotoSource.camera,
      ),
      capturedAt: row.capturedAt,
      createdAt: row.createdAt,
      modifiedAt: row.modifiedAt,
    );
  }
}

import 'package:drift/drift.dart' show Value;

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db_pkg;
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final db_pkg.AppDatabase _db;
  ProfileRepositoryImpl(this._db);

  @override
  Stream<List<Profile>> watchProfiles() => _db.profileDao.watchProfiles().map(
    (rows) => rows.map(_toDomain).toList(),
  );

  @override
  Future<Result<Profile>> getProfile(String id) async {
    try {
      final row = await _db.profileDao.getProfile(id);
      if (row == null) {
        return const Err(DatabaseFailure('Profile not found'));
      }
      return Success(_toDomain(row));
    } catch (e) {
      return Err(DatabaseFailure('Failed to get profile: $e'));
    }
  }

  @override
  Future<Result<Profile>> createProfile(Profile profile) async {
    try {
      final now = DateTime.now();
      await _db.profileDao.insertProfile(
        db_pkg.ProfilesCompanion.insert(
          id: profile.id,
          name: profile.name,
          colorHex: Value(profile.colorHex),
          avatarEmoji: Value(profile.avatarEmoji),
          isDefault: Value(profile.isDefault),
          createdAt: now,
          modifiedAt: now,
        ),
      );
      final row = await _db.profileDao.getProfile(profile.id);
      if (row == null) {
        return const Err(DatabaseFailure('Profile not found after insert'));
      }
      return Success(_toDomain(row));
    } catch (e) {
      return Err(DatabaseFailure('Failed to create profile: $e'));
    }
  }

  @override
  Future<Result<Profile>> updateProfile(Profile profile) async {
    try {
      await _db.profileDao.updateProfile(
        db_pkg.ProfilesCompanion(
          id: Value(profile.id),
          name: Value(profile.name),
          colorHex: Value(profile.colorHex),
          avatarEmoji: Value(profile.avatarEmoji),
          isDefault: Value(profile.isDefault),
        ),
      );
      final row = await _db.profileDao.getProfile(profile.id);
      if (row == null) {
        return const Err(DatabaseFailure('Profile not found after update'));
      }
      return Success(_toDomain(row));
    } catch (e) {
      return Err(DatabaseFailure('Failed to update profile: $e'));
    }
  }

  @override
  Future<Result<void>> deleteProfile(String id) async {
    try {
      final row = await _db.profileDao.getProfile(id);
      if (row == null) {
        return const Err(DatabaseFailure('Profile not found'));
      }
      if (row.isDefault) {
        return const Err(DatabaseFailure('Cannot delete the default profile'));
      }
      await _db.profileDao.softDeleteProfile(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete profile: $e'));
    }
  }

  @override
  Future<Result<void>> setDefault(String id) async {
    try {
      final row = await _db.profileDao.getProfile(id);
      if (row == null) {
        return const Err(DatabaseFailure('Profile not found'));
      }
      await _db.profileDao.setDefault(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to set default profile: $e'));
    }
  }

  Profile _toDomain(db_pkg.Profile row) => Profile(
    id: row.id,
    name: row.name,
    colorHex: row.colorHex,
    avatarEmoji: row.avatarEmoji,
    isDefault: row.isDefault,
    createdAt: row.createdAt,
    modifiedAt: row.modifiedAt,
  );
}

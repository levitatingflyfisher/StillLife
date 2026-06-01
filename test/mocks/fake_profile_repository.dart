import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/profiles/domain/entities/profile.dart';
import 'package:still_life/features/profiles/domain/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  final List<Profile> _profiles = [];

  @override
  Stream<List<Profile>> watchProfiles() =>
      Stream.value(List.unmodifiable(_profiles));

  @override
  Future<Result<Profile>> getProfile(String id) async {
    final match = _profiles.where((p) => p.id == id).firstOrNull;
    if (match == null) {
      return const Err(DatabaseFailure('Profile not found'));
    }
    return Success(match);
  }

  @override
  Future<Result<Profile>> createProfile(Profile profile) async {
    _profiles.add(profile);
    return Success(profile);
  }

  @override
  Future<Result<Profile>> updateProfile(Profile profile) async {
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx < 0) return const Err(DatabaseFailure('Profile not found'));
    _profiles[idx] = profile;
    return Success(profile);
  }

  @override
  Future<Result<void>> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    return const Success(null);
  }

  @override
  Future<Result<void>> setDefault(String id) async {
    for (var i = 0; i < _profiles.length; i++) {
      _profiles[i] = _profiles[i].copyWith(isDefault: _profiles[i].id == id);
    }
    return const Success(null);
  }
}

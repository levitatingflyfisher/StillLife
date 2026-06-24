import '../../../../core/errors/result.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  Stream<List<Profile>> watchProfiles();
  Future<Result<Profile>> getProfile(String id);
  Future<Result<Profile>> createProfile(Profile profile);
  Future<Result<Profile>> updateProfile(Profile profile);
  Future<Result<void>> deleteProfile(String id); // returns Failure if isDefault
  Future<Result<void>> setDefault(String id);
}

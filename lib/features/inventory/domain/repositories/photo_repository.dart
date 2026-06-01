import '../../../../core/errors/result.dart';
import '../entities/photo.dart';

abstract class PhotoRepository {
  Stream<List<Photo>> watchItemPhotos(String itemId);
  Future<Result<Photo>> addPhoto(Photo photo);
  Future<Result<void>> deletePhoto(String id);
  Future<Result<void>> setPrimaryPhoto(String itemId, String photoId);
  Future<Result<Photo?>> getPrimaryPhoto(String itemId);
}

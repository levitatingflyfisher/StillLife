import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class PhotoStorageService {
  static const _photosDir = 'photos';
  static const _thumbsDir = 'thumbnails';
  static const int thumbnailWidth = 200;

  Future<Directory> _getPhotosDir(String itemId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, _photosDir, itemId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _getThumbsDir(String itemId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, _thumbsDir, itemId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Save a photo file for an item. Returns the saved file path.
  Future<String> savePhoto({
    required String itemId,
    required String sourcePath,
  }) async {
    final photosDir = await _getPhotosDir(itemId);
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final fileName = '${_uuid.v4()}$ext';
    final destPath = p.join(photosDir.path, fileName);

    await File(sourcePath).copy(destPath);
    await _generateThumbnail(
      itemId: itemId,
      fileName: fileName,
      sourcePath: destPath,
    );

    return destPath;
  }

  /// Save photo from bytes. Returns the saved file path.
  Future<String> savePhotoBytes({
    required String itemId,
    required Uint8List bytes,
    String extension = '.jpg',
  }) async {
    final photosDir = await _getPhotosDir(itemId);
    final fileName = '${_uuid.v4()}$extension';
    final destPath = p.join(photosDir.path, fileName);

    await File(destPath).writeAsBytes(bytes);
    await _generateThumbnail(
      itemId: itemId,
      fileName: fileName,
      sourcePath: destPath,
    );

    return destPath;
  }

  Future<void> _generateThumbnail({
    required String itemId,
    required String fileName,
    required String sourcePath,
  }) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return;

      final thumbnail = img.copyResize(image, width: thumbnailWidth);
      final thumbBytes = img.encodeJpg(thumbnail, quality: 80);

      final thumbsDir = await _getThumbsDir(itemId);
      final thumbPath = p.join(thumbsDir.path, fileName);
      await File(thumbPath).writeAsBytes(thumbBytes);
    } catch (_) {
      // Thumbnail generation is best-effort
    }
  }

  /// Get the thumbnail path for a photo. Returns null if not found.
  Future<String?> getThumbnailPath(String itemId, String photoPath) async {
    final fileName = p.basename(photoPath);
    final thumbsDir = await _getThumbsDir(itemId);
    final thumbPath = p.join(thumbsDir.path, fileName);
    if (await File(thumbPath).exists()) {
      return thumbPath;
    }
    return null;
  }

  /// Delete a photo and its thumbnail.
  Future<void> deletePhoto(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Try to delete thumbnail
    final fileName = p.basename(filePath);
    final parentDir = p.basename(p.dirname(filePath));
    final appDir = await getApplicationDocumentsDirectory();
    final thumbPath = p.join(appDir.path, _thumbsDir, parentDir, fileName);
    final thumbFile = File(thumbPath);
    if (await thumbFile.exists()) {
      await thumbFile.delete();
    }
  }

  /// Delete all photos for an item.
  Future<void> deleteAllPhotos(String itemId) async {
    final appDir = await getApplicationDocumentsDirectory();

    final photosDir = Directory(p.join(appDir.path, _photosDir, itemId));
    if (await photosDir.exists()) {
      await photosDir.delete(recursive: true);
    }

    final thumbsDir = Directory(p.join(appDir.path, _thumbsDir, itemId));
    if (await thumbsDir.exists()) {
      await thumbsDir.delete(recursive: true);
    }
  }

  /// Check if a photo file exists on disk.
  Future<bool> photoExists(String filePath) async {
    return File(filePath).exists();
  }
}

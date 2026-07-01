import 'dart:typed_data';

import 'legacy_photo_files/legacy_photo_files.dart';
import 'photo_bytes.dart';

/// Photo storage after schema v12: bytes live in the database as BLOBs, so
/// this service is platform-neutral. Its two remaining jobs:
///
///  * derive thumbnails from captured bytes (pure Dart, works on web), and
///  * clean up LEGACY pre-v12 photo files on native so they don't leak disk
///    (a no-op on web, which never had photo files).
class PhotoStorageService {
  static const int thumbnailWidth = kThumbnailWidth;

  /// Builds a JPEG thumbnail for [bytes]; null when the image can't be
  /// decoded (thumbnails are best-effort).
  Uint8List? thumbnailFor(Uint8List bytes) => buildThumbnailBytes(bytes);

  /// Deletes a legacy photo file (and its sibling thumbnail) from disk.
  /// Safe to call with '' — byte-backed photos have no file to delete.
  Future<void> deletePhoto(String filePath) => deleteLegacyPhotoFile(filePath);

  /// Deletes all legacy photo files for an item.
  Future<void> deleteAllPhotos(String itemId) =>
      deleteAllLegacyPhotoFiles(itemId);
}

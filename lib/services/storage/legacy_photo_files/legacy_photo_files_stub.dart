import 'dart:typed_data';

/// The web never had filesystem photos, so there is nothing to read.
Future<Uint8List?> readLegacyPhotoFile(String path) async => null;

/// The web never had filesystem photos, so there is nothing to delete.
Future<void> deleteLegacyPhotoFile(String filePath) async {}

/// The web never had filesystem photos, so there is nothing to delete.
Future<void> deleteAllLegacyPhotoFiles(String itemId) async {}

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Reads a legacy photo file from disk. Returns null when the file is
/// missing or unreadable — callers keep the database row either way.
Future<Uint8List?> readLegacyPhotoFile(String path) async {
  try {
    return await File(path).readAsBytes();
  } catch (_) {
    return null;
  }
}

/// Best-effort delete of a legacy photo file and its sibling thumbnail
/// (`<documents>/thumbnails/<itemId>/<fileName>`).
Future<void> deleteLegacyPhotoFile(String filePath) async {
  if (filePath.isEmpty) return;
  try {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    final fileName = p.basename(filePath);
    final parentDir = p.basename(p.dirname(filePath));
    final appDir = await getApplicationDocumentsDirectory();
    final thumbFile = File(
      p.join(appDir.path, 'thumbnails', parentDir, fileName),
    );
    if (await thumbFile.exists()) {
      await thumbFile.delete();
    }
  } catch (_) {
    // Legacy cleanup is best-effort; the BLOB row is the source of truth.
  }
}

/// Best-effort delete of every legacy photo file for [itemId].
Future<void> deleteAllLegacyPhotoFiles(String itemId) async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    for (final dirName in const ['photos', 'thumbnails']) {
      final dir = Directory(p.join(appDir.path, dirName, itemId));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  } catch (_) {
    // Legacy cleanup is best-effort; the BLOB rows are the source of truth.
  }
}

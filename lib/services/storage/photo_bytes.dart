import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Width of generated photo thumbnails, in pixels.
const int kThumbnailWidth = 200;

/// Builds a JPEG thumbnail from full-size image [bytes].
///
/// Pure Dart (package:image), so it runs identically on native and web.
/// Returns null when [bytes] is not a decodable image — thumbnails are
/// best-effort and must never fail a save or a migration.
Uint8List? buildThumbnailBytes(
  Uint8List bytes, {
  int width = kThumbnailWidth,
  int quality = 80,
}) {
  try {
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    final thumbnail = img.copyResize(image, width: width);
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: quality));
  } catch (_) {
    return null;
  }
}

import 'dart:typed_data';

/// Sniffs the media type of [bytes] from its magic numbers.
///
/// The analysis providers must declare the media type that matches the
/// actual bytes: still photos arrive as JPEG (image_picker re-encodes),
/// but video-walkthrough frames are ffmpeg PNGs — and the Anthropic
/// Messages API rejects a base64 image block whose declared media_type
/// mismatches the payload with a 400.
///
/// Unknown signatures default to `image/jpeg`, preserving the previous
/// behavior for the camera paths.
String detectImageMediaType(Uint8List bytes) {
  bool startsWith(List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return 'image/png';
  }
  if (startsWith(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith(const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  // RIFF....WEBP
  if (bytes.length >= 12 &&
      startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/image_media_type.dart';

Uint8List _bytes(List<int> header) =>
    Uint8List.fromList([...header, ...List.filled(16, 0)]);

void main() {
  group('detectImageMediaType', () {
    test('recognises PNG magic bytes — video frames are ffmpeg PNGs', () {
      expect(
        detectImageMediaType(
          _bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        ),
        'image/png',
      );
    });

    test('recognises JPEG magic bytes', () {
      expect(
        detectImageMediaType(_bytes([0xFF, 0xD8, 0xFF, 0xE0])),
        'image/jpeg',
      );
    });

    test('recognises GIF and WebP', () {
      expect(
        detectImageMediaType(_bytes('GIF89a'.codeUnits)),
        'image/gif',
      );
      expect(
        detectImageMediaType(
          Uint8List.fromList([
            ...'RIFF'.codeUnits,
            0, 0, 0, 0,
            ...'WEBP'.codeUnits,
          ]),
        ),
        'image/webp',
      );
    });

    test('defaults unknown bytes to image/jpeg (image_picker re-encodes)',
        () {
      expect(detectImageMediaType(_bytes([1, 2, 3, 4])), 'image/jpeg');
      expect(detectImageMediaType(Uint8List(0)), 'image/jpeg');
    });
  });
}

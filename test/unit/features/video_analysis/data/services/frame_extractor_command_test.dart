import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/data/services/frame_extractor_io.dart';

void main() {
  group('buildFrameExtractionCommand — bounded memory', () {
    test('downscales frames to a bounded long edge', () {
      final cmd = buildFrameExtractionCommand(
        videoPath: '/tmp/walk.mp4',
        fps: 2.0,
        outputPattern: '/tmp/frames/frame_%05d.jpg',
      );
      expect(cmd, contains('scale='),
          reason: 'native-resolution frames (1-3 MB each at 1080p+) are '
              'buffered per run — a 4-minute walkthrough at 2 fps OOM-kills '
              'the app without a resolution cap');
      expect(cmd, contains('min($kMaxFrameLongEdge,iw)'));
      expect(cmd, contains('force_original_aspect_ratio=decrease'),
          reason: 'portrait walkthroughs must be capped on the long edge '
              'too, and small videos must not be upscaled');
    });

    test('emits compressed JPEG frames, not full PNGs', () {
      final cmd = buildFrameExtractionCommand(
        videoPath: '/tmp/walk.mp4',
        fps: 2.0,
        outputPattern: '/tmp/frames/frame_%05d.jpg',
      );
      expect(cmd, contains('frame_%05d.jpg'));
      expect(cmd, contains('-q:v'),
          reason: 'a quality dial keeps per-frame bytes bounded');
      expect(cmd, contains('fps=2.0'));
      expect(cmd, contains('"/tmp/walk.mp4"'));
    });
  });
}

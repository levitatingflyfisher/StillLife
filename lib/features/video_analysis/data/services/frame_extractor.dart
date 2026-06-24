import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'package:still_life/features/video_analysis/domain/entities/frame_data.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

/// Extracts frames from video files at a configurable FPS, computing quality
/// metrics (blur/sharpness and perceptual hash) for each frame.
///
/// Heavy image processing runs in a Dart [Isolate] to keep the UI responsive.
class FrameExtractor {
  final String _tempDir;

  /// Creates a [FrameExtractor] that writes temporary frame images to
  /// [tempDir].
  FrameExtractor({required String tempDir}) : _tempDir = tempDir;

  /// Extracts frames from [videoPath] at the rate specified by [config] and
  /// yields [FrameData] instances as each frame is processed.
  ///
  /// Frames whose sharpness falls below [config.blurThreshold] are still
  /// emitted -- callers can filter them using [FrameData.isSharp].
  Stream<FrameData> extractFrames({
    required String videoPath,
    required AnalysisConfig config,
  }) async* {
    final fps = config.framesPerSecond;
    final outputPattern = p.join(_tempDir, 'frame_%05d.png');

    // Use ffmpeg to extract frames at the requested FPS.
    final session = await FFmpegKit.execute(
      '-i "$videoPath" -vf "fps=$fps" -vsync vfr "$outputPattern"',
    );

    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getLogsAsString();
      throw FrameExtractionException(
        'FFmpeg frame extraction failed (rc: ${returnCode?.getValue()}): $logs',
      );
    }

    // Enumerate generated frame files in sorted order.
    final frameFiles = await _listFrameFiles();
    if (frameFiles.isEmpty) return;

    for (var i = 0; i < frameFiles.length; i++) {
      final bytes = await frameFiles[i].readAsBytes();
      final timestamp = i / fps;

      // Run heavy image analysis in an isolate.
      final metrics = await Isolate.run(() => _computeFrameMetrics(bytes));

      yield FrameData(
        index: i,
        timestamp: timestamp,
        imageBytes: bytes,
        width: metrics.width,
        height: metrics.height,
        sharpness: metrics.sharpness,
        perceptualHash: metrics.perceptualHash,
      );
    }
  }

  /// Lists frame PNG files in the temp directory, sorted by name.
  Future<List<File>> _listFrameFiles() async {
    final dir = Directory(_tempDir);
    if (!await dir.exists()) return const [];

    final entities = await dir.list().toList();
    final frameFiles =
        entities
            .whereType<File>()
            .where(
              (f) =>
                  p.basename(f.path).startsWith('frame_') &&
                  f.path.endsWith('.png'),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    return frameFiles;
  }
}

/// Holds computed quality metrics for a single frame.
class _FrameMetrics {
  final int width;
  final int height;
  final double sharpness;
  final String perceptualHash;

  const _FrameMetrics({
    required this.width,
    required this.height,
    required this.sharpness,
    required this.perceptualHash,
  });
}

/// Computes blur metric (Laplacian variance) and perceptual hash for a frame.
///
/// This function is designed to run inside an [Isolate].
_FrameMetrics _computeFrameMetrics(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes);
  if (image == null) {
    return const _FrameMetrics(
      width: 0,
      height: 0,
      sharpness: 0.0,
      perceptualHash: '',
    );
  }

  final sharpness = _computeLaplacianVariance(image);
  final hash = _computePerceptualHash(image);

  return _FrameMetrics(
    width: image.width,
    height: image.height,
    sharpness: sharpness,
    perceptualHash: hash,
  );
}

/// Computes the Laplacian variance of [image] as a sharpness metric.
///
/// Higher values indicate a sharper image; lower values indicate blur.
/// Uses the 3x3 Laplacian kernel: [[0,1,0],[1,-4,1],[0,1,0]].
double _computeLaplacianVariance(img.Image image) {
  final grayscale = img.grayscale(image);
  final w = grayscale.width;
  final h = grayscale.height;

  // Laplacian kernel: [[0,1,0],[1,-4,1],[0,1,0]]
  final values = <double>[];

  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final center = grayscale.getPixel(x, y).r.toDouble();
      final top = grayscale.getPixel(x, y - 1).r.toDouble();
      final bottom = grayscale.getPixel(x, y + 1).r.toDouble();
      final left = grayscale.getPixel(x - 1, y).r.toDouble();
      final right = grayscale.getPixel(x + 1, y).r.toDouble();

      final laplacian = top + bottom + left + right - 4.0 * center;
      values.add(laplacian);
    }
  }

  if (values.isEmpty) return 0.0;

  // Compute variance.
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance =
      values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
      values.length;

  return variance;
}

/// Computes a simple perceptual hash (pHash) of [image] for deduplication.
///
/// Resizes to 8x8, converts to grayscale, then produces a 64-bit hash based
/// on whether each pixel is above or below the mean luminance.
String _computePerceptualHash(img.Image image) {
  // Resize to 8x8 for a compact hash.
  final small = img.copyResize(image, width: 8, height: 8);
  final gray = img.grayscale(small);

  // Collect luminance values.
  final luminances = <double>[];
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      luminances.add(gray.getPixel(x, y).r.toDouble());
    }
  }

  final mean = luminances.reduce((a, b) => a + b) / luminances.length;

  // Build a 64-bit hash as a hex string.
  final buffer = StringBuffer();
  for (var i = 0; i < luminances.length; i += 4) {
    var nibble = 0;
    for (var j = 0; j < 4 && i + j < luminances.length; j++) {
      if (luminances[i + j] >= mean) {
        nibble |= (1 << (3 - j));
      }
    }
    buffer.write(nibble.toRadixString(16));
  }

  return buffer.toString();
}

/// Exception thrown when frame extraction fails.
class FrameExtractionException implements Exception {
  final String message;
  const FrameExtractionException(this.message);

  @override
  String toString() => 'FrameExtractionException: $message';
}

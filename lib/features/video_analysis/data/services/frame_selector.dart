import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';
import 'package:still_life/features/video_analysis/domain/entities/frame_data.dart';

/// Selects the best frame for each [TrackedObject] using a weighted scoring
/// function, then crops the object region from that frame.
///
/// Scoring weights:
/// - Area: 0.5 (larger bounding boxes are preferred)
/// - Sharpness: 0.3 (sharper frames are preferred)
/// - Centering: 0.2 (objects closer to frame center are preferred)
class FrameSelector {
  final double _areaWeight;
  final double _sharpnessWeight;
  final double _centeringWeight;
  final double _paddingFraction;

  /// Creates a [FrameSelector] with configurable scoring weights.
  ///
  /// [paddingFraction] controls how much padding (as a fraction of the
  /// bounding box dimensions) is added when cropping. Default is 0.1 (10%).
  FrameSelector({
    double areaWeight = 0.5,
    double sharpnessWeight = 0.3,
    double centeringWeight = 0.2,
    double paddingFraction = 0.1,
  }) : _areaWeight = areaWeight,
       _sharpnessWeight = sharpnessWeight,
       _centeringWeight = centeringWeight,
       _paddingFraction = paddingFraction;

  /// Selects the best frame for each tracked object.
  ///
  /// [trackedObjects] are the objects to process.
  /// [frames] maps frame index to [FrameData] for lookup.
  ///
  /// Returns a new list of [TrackedObject] instances with [bestFrameIndex]
  /// and [bestBoundingBox] set to the highest-scoring detection.
  List<TrackedObject> selectBestFrames({
    required List<TrackedObject> trackedObjects,
    required Map<int, FrameData> frames,
  }) {
    return trackedObjects.map((tracked) {
      final best = _bestDetection(tracked, frames);
      return TrackedObject(
        id: tracked.id,
        detections: tracked.detections,
        bestFrameIndex: best.frameIndex,
        bestBoundingBox: best.boundingBox,
      );
    }).toList();
  }

  /// Crops the object from the best frame of each [TrackedObject].
  ///
  /// Returns a map of tracked object ID to cropped image bytes (PNG encoded).
  Map<String, Uint8List> cropBestFrames({
    required List<TrackedObject> trackedObjects,
    required Map<int, FrameData> frames,
  }) {
    final crops = <String, Uint8List>{};

    for (final tracked in trackedObjects) {
      final frame = frames[tracked.bestFrameIndex];
      if (frame == null) continue;

      final cropped = cropDetection(
        imageBytes: frame.imageBytes,
        boundingBox: tracked.bestBoundingBox,
        imageWidth: frame.width,
        imageHeight: frame.height,
      );

      if (cropped != null) {
        crops[tracked.id] = cropped;
      }
    }

    return crops;
  }

  /// Crops a single detection region from an image with padding.
  ///
  /// Returns PNG-encoded bytes of the cropped region, or `null` if the
  /// image cannot be decoded or the crop region is invalid.
  Uint8List? cropDetection({
    required Uint8List imageBytes,
    required Rect boundingBox,
    required int imageWidth,
    required int imageHeight,
  }) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    final padX = boundingBox.width * _paddingFraction;
    final padY = boundingBox.height * _paddingFraction;

    final x = math.max(0, (boundingBox.left - padX).round());
    final y = math.max(0, (boundingBox.top - padY).round());
    final w = math.min(imageWidth - x, (boundingBox.width + 2 * padX).round());
    final h = math.min(
      imageHeight - y,
      (boundingBox.height + 2 * padY).round(),
    );

    if (w <= 0 || h <= 0) return null;

    final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
    return Uint8List.fromList(img.encodePng(cropped));
  }

  /// Finds the highest-scoring detection in a tracked object.
  Detection _bestDetection(TrackedObject tracked, Map<int, FrameData> frames) {
    Detection? best;
    double bestScore = -1.0;

    for (final detection in tracked.detections) {
      final frame = frames[detection.frameIndex];
      if (frame == null) continue;

      final score = _computeScore(detection, frame);
      if (score > bestScore) {
        bestScore = score;
        best = detection;
      }
    }

    // Fallback to first detection if no frames were found in the map.
    return best ?? tracked.detections.first;
  }

  /// Computes a weighted quality score for a detection in a frame.
  double _computeScore(Detection detection, FrameData frame) {
    final areaScore = _normalizeArea(detection, frame);
    final sharpnessScore = _normalizeSharpness(frame);
    final centeringScore = _normalizeCentering(detection, frame);

    return _areaWeight * areaScore +
        _sharpnessWeight * sharpnessScore +
        _centeringWeight * centeringScore;
  }

  /// Normalizes the detection area relative to the frame area.
  ///
  /// Returns a value in [0, 1] where larger detections score higher.
  /// Capped at 50% of frame area to avoid overly-large (likely incorrect)
  /// detections dominating.
  double _normalizeArea(Detection detection, FrameData frame) {
    final frameArea = frame.width * frame.height;
    if (frameArea == 0) return 0.0;
    final ratio = detection.area / frameArea;
    return math.min(ratio / 0.5, 1.0);
  }

  /// Normalizes frame sharpness to [0, 1] using a sigmoid curve.
  ///
  /// Sharpness values above ~500 all score near 1.0.
  double _normalizeSharpness(FrameData frame) {
    return 1.0 / (1.0 + math.exp(-0.01 * (frame.sharpness - 100)));
  }

  /// Normalizes how centered the detection is within the frame.
  ///
  /// Returns a value in [0, 1] where 1.0 means perfectly centered.
  double _normalizeCentering(Detection detection, FrameData frame) {
    if (frame.width == 0 || frame.height == 0) return 0.0;

    final box = detection.boundingBox;
    final detectCenterX = box.left + box.width / 2;
    final detectCenterY = box.top + box.height / 2;

    final frameCenterX = frame.width / 2;
    final frameCenterY = frame.height / 2;

    // Normalized distance from center (0 = at center, 1 = at corner).
    final dx = (detectCenterX - frameCenterX).abs() / frameCenterX;
    final dy = (detectCenterY - frameCenterY).abs() / frameCenterY;
    final distance = math.sqrt(dx * dx + dy * dy) / math.sqrt2;

    return 1.0 - distance.clamp(0.0, 1.0);
  }
}

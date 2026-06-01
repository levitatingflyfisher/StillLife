import 'dart:ui';

import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';

import 'object_detector.dart' show computeIoU;

/// Groups [Detection] objects across consecutive frames into [TrackedObject]
/// instances using IoU-based greedy matching.
///
/// This service is stateless per invocation — call [trackDetections] with all
/// frame detections at once, or use [TrackingState] for incremental tracking.
class ObjectTracker {
  final double _iouThreshold;

  /// Creates an [ObjectTracker].
  ///
  /// [iouThreshold] controls how similar two bounding boxes must be (IoU) to
  /// be considered the same object across frames. Default is 0.3.
  ObjectTracker({double iouThreshold = 0.3}) : _iouThreshold = iouThreshold;

  /// Tracks objects across all frames given a map of frame index to detections.
  ///
  /// [detectionsByFrame] maps each frame index to the list of [Detection]
  /// objects found in that frame. Frame indices should be processed in order.
  ///
  /// Returns a list of [TrackedObject] instances, each containing all
  /// detections believed to belong to the same physical object.
  List<TrackedObject> trackDetections(
    Map<int, List<Detection>> detectionsByFrame,
  ) {
    final state = TrackingState(iouThreshold: _iouThreshold);

    // Process frames in order.
    final sortedFrames = detectionsByFrame.keys.toList()..sort();
    for (final frameIndex in sortedFrames) {
      final detections = detectionsByFrame[frameIndex]!;
      state.processFrame(detections);
    }

    return state.finalize();
  }
}

/// Mutable tracking state for incremental frame-by-frame processing.
///
/// Use this when frames arrive over time (e.g., from a stream) rather than
/// all at once.
class TrackingState {
  final double iouThreshold;
  final List<_Track> _activeTracks = [];
  int _nextTrackId = 0;

  TrackingState({this.iouThreshold = 0.3});

  /// Processes detections from a single frame, matching them to existing
  /// tracks or creating new ones.
  void processFrame(List<Detection> detections) {
    if (detections.isEmpty) return;

    // Track which active tracks and detections have been matched.
    final matchedTracks = <int>{};
    final matchedDetections = <int>{};

    // Build a list of (trackIdx, detectionIdx, iou) candidates.
    final candidates = <_MatchCandidate>[];
    for (var t = 0; t < _activeTracks.length; t++) {
      final track = _activeTracks[t];
      final lastBox = track.lastBoundingBox;

      for (var d = 0; d < detections.length; d++) {
        final detection = detections[d];

        // Only match detections with the same label.
        if (detection.label != track.label) continue;

        final iou = computeIoU(lastBox, detection.boundingBox);
        if (iou > iouThreshold) {
          candidates.add(_MatchCandidate(t, d, iou));
        }
      }
    }

    // Greedy matching: sort by IoU descending, assign best matches first.
    candidates.sort((a, b) => b.iou.compareTo(a.iou));

    for (final candidate in candidates) {
      if (matchedTracks.contains(candidate.trackIndex) ||
          matchedDetections.contains(candidate.detectionIndex)) {
        continue;
      }

      _activeTracks[candidate.trackIndex].addDetection(
        detections[candidate.detectionIndex],
      );
      matchedTracks.add(candidate.trackIndex);
      matchedDetections.add(candidate.detectionIndex);
    }

    // Create new tracks for unmatched detections.
    for (var d = 0; d < detections.length; d++) {
      if (!matchedDetections.contains(d)) {
        _activeTracks.add(
          _Track(
            id: 'track_${_nextTrackId++}',
            initialDetection: detections[d],
          ),
        );
      }
    }
  }

  /// Finalizes tracking and returns the list of [TrackedObject] instances.
  ///
  /// Each tracked object contains all detections assigned to that track.
  /// The [bestFrameIndex] and [bestBoundingBox] are set to the detection
  /// with the highest confidence (will be refined by [FrameSelector]).
  List<TrackedObject> finalize() {
    return _activeTracks.map((track) {
      // Default: pick the detection with highest confidence.
      final best = track.detections.reduce(
        (a, b) => a.confidence > b.confidence ? a : b,
      );

      return TrackedObject(
        id: track.id,
        detections: List.unmodifiable(track.detections),
        bestFrameIndex: best.frameIndex,
        bestBoundingBox: best.boundingBox,
      );
    }).toList();
  }
}

/// Internal mutable representation of an in-progress track.
class _Track {
  final String id;
  final List<Detection> detections;

  _Track({required this.id, required Detection initialDetection})
    : detections = [initialDetection];

  String get label => detections.first.label;
  Rect get lastBoundingBox => detections.last.boundingBox;

  void addDetection(Detection detection) {
    detections.add(detection);
  }
}

/// A candidate match between a track and a detection, ranked by IoU.
class _MatchCandidate {
  final int trackIndex;
  final int detectionIndex;
  final double iou;

  const _MatchCandidate(this.trackIndex, this.detectionIndex, this.iou);
}

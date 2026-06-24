import 'dart:async';

import 'package:still_life/features/video_analysis/domain/entities/analysis_session.dart';
import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';
import 'package:still_life/features/video_analysis/domain/entities/frame_data.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

import 'classifier.dart';
import 'frame_extractor.dart';
import 'frame_selector.dart';
import 'object_detector.dart';
import 'object_tracker.dart';

/// Coordinates the full video analysis pipeline:
///
/// 1. **Extract** frames from video at configured FPS
/// 2. **Detect** objects in each frame via YOLOv8
/// 3. **Track** detections across frames into unique objects
/// 4. **Select** the best frame/crop for each tracked object
/// 5. **Classify** each crop via MobileNetV3
/// 6. **Enhance** (optional) via LLM provider for richer metadata
///
/// Emits [AnalysisProgress] updates through a stream for UI consumption and
/// maintains an [AnalysisSession] that reflects the current pipeline state.
class AnalysisOrchestrator {
  final FrameExtractor _frameExtractor;
  final ObjectDetector _objectDetector;
  final ObjectTracker _objectTracker;
  final FrameSelector _frameSelector;
  final Classifier _classifier;
  final AnalysisProvider? _analysisProvider;

  /// Creates an [AnalysisOrchestrator] with all pipeline components.
  ///
  /// [analysisProvider] is optional — when provided, detected objects will be
  /// enhanced with LLM-generated metadata (Tier 2/3/4). If omitted or if the
  /// provider is unavailable, on-device results are kept as-is.
  AnalysisOrchestrator({
    required FrameExtractor frameExtractor,
    required ObjectDetector objectDetector,
    required ObjectTracker objectTracker,
    required FrameSelector frameSelector,
    required Classifier classifier,
    AnalysisProvider? analysisProvider,
  }) : _frameExtractor = frameExtractor,
       _objectDetector = objectDetector,
       _objectTracker = objectTracker,
       _frameSelector = frameSelector,
       _classifier = classifier,
       _analysisProvider = analysisProvider;

  /// Runs the full analysis pipeline on [videoPath].
  ///
  /// Returns a stream of [AnalysisProgress] updates. The final
  /// [AnalysisSession] can be retrieved from [lastSession] after the stream
  /// completes.
  ///
  /// The pipeline handles partial failures gracefully:
  /// - If object detection fails on a frame, that frame is skipped.
  /// - If classification fails, the YOLO label is used as fallback.
  /// - If LLM enhancement fails, on-device results are preserved.
  Stream<AnalysisProgress> analyze({
    required String videoPath,
    required AnalysisConfig config,
    String? sessionId,
    String? roomId,
  }) async* {
    final session = AnalysisSession(
      id: sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      videoPath: videoPath,
      roomId: roomId,
      startedAt: DateTime.now(),
      providerTier: _analysisProvider?.tier ?? AnalysisTier.onDevice,
    );

    _lastSession = session.copyWith(status: AnalysisStatus.extracting);

    // ── Stage 1: Frame Extraction ──────────────────────────────────────
    yield _progress(stage: 'Extracting frames', currentFrame: 0);

    final frames = <int, FrameData>{};
    final frameStream = _frameExtractor.extractFrames(
      videoPath: videoPath,
      config: config,
    );

    await for (final frame in frameStream) {
      frames[frame.index] = frame;

      yield _progress(
        stage: 'Extracting frames',
        currentFrame: frame.index + 1,
        totalFrames: frame.index + 1, // Updated as we discover total.
      );
    }

    final totalFrames = frames.length;
    _lastSession = _lastSession!.copyWith(
      status: AnalysisStatus.detecting,
      totalFrames: totalFrames,
    );

    // ── Stage 2: Object Detection ──────────────────────────────────────
    yield _progress(stage: 'Detecting objects', totalFrames: totalFrames);

    final detectionsByFrame = <int, List<Detection>>{};
    var processedFrames = 0;
    var totalDetections = 0;

    for (final entry in frames.entries) {
      final frameIndex = entry.key;
      final frame = entry.value;

      try {
        final detections = await _objectDetector.detect(
          imageBytes: frame.imageBytes,
          frameIndex: frameIndex,
        );

        if (detections.isNotEmpty) {
          detectionsByFrame[frameIndex] = detections;
          totalDetections += detections.length;
        }
      } catch (_) {
        // Skip frames where detection fails.
      }

      processedFrames++;
      yield _progress(
        stage: 'Detecting objects',
        currentFrame: processedFrames,
        totalFrames: totalFrames,
        itemsDetected: totalDetections,
      );
    }

    _lastSession = _lastSession!.copyWith(
      status: AnalysisStatus.tracking,
      processedFrames: processedFrames,
    );

    // ── Stage 3: Object Tracking ───────────────────────────────────────
    yield _progress(
      stage: 'Tracking objects',
      currentFrame: processedFrames,
      totalFrames: totalFrames,
      itemsDetected: totalDetections,
    );

    final trackedObjects = _objectTracker.trackDetections(detectionsByFrame);

    _lastSession = _lastSession!.copyWith(status: AnalysisStatus.selecting);

    // ── Stage 4: Best Frame Selection ──────────────────────────────────
    yield _progress(
      stage: 'Selecting best frames',
      currentFrame: processedFrames,
      totalFrames: totalFrames,
      itemsDetected: trackedObjects.length,
    );

    final selectedObjects = _frameSelector.selectBestFrames(
      trackedObjects: trackedObjects,
      frames: frames,
    );

    final croppedImages = _frameSelector.cropBestFrames(
      trackedObjects: selectedObjects,
      frames: frames,
    );

    _lastSession = _lastSession!.copyWith(status: AnalysisStatus.classifying);

    // ── Stage 5: Classification ────────────────────────────────────────
    yield _progress(
      stage: 'Classifying items',
      currentFrame: processedFrames,
      totalFrames: totalFrames,
      itemsDetected: selectedObjects.length,
    );

    final detectedObjects = <DetectedObject>[];

    for (final tracked in selectedObjects) {
      final cropped = croppedImages[tracked.id];
      if (cropped == null) continue;

      // Classify the cropped object.
      String? category;
      String label = tracked.label;
      double confidence = tracked.maxConfidence;

      try {
        final result = await _classifier.classify(cropped);
        if (result != null && result.confidence > confidence) {
          category = result.category;
          label = result.label;
          confidence = result.confidence;
        }
      } catch (_) {
        // Keep YOLO label on classification failure.
      }

      detectedObjects.add(
        DetectedObject(
          id: tracked.id,
          label: label,
          confidence: confidence,
          boundingBox: tracked.bestBoundingBox,
          croppedImage: cropped,
          frameIndex: tracked.bestFrameIndex,
          category: category,
        ),
      );

      // Enforce max objects limit.
      if (detectedObjects.length >= config.maxObjectsPerSession) break;
    }

    // ── Stage 6: LLM Enhancement (optional) ────────────────────────────
    if (config.enhanceWithLlm && _analysisProvider != null) {
      _lastSession = _lastSession!.copyWith(status: AnalysisStatus.enhancing);

      yield _progress(
        stage: 'Enhancing with AI',
        currentFrame: processedFrames,
        totalFrames: totalFrames,
        itemsDetected: detectedObjects.length,
      );

      final enhanced = await _enhanceWithProvider(detectedObjects, frames);
      detectedObjects
        ..clear()
        ..addAll(enhanced);
    }

    // ── Complete ───────────────────────────────────────────────────────
    _lastSession = _lastSession!.copyWith(
      status: AnalysisStatus.reviewing,
      detectedObjects: detectedObjects,
      completedAt: DateTime.now(),
    );

    yield _progress(
      stage: 'Ready for review',
      currentFrame: totalFrames,
      totalFrames: totalFrames,
      itemsDetected: detectedObjects.length,
    );
  }

  /// Enhances detected objects using the configured [AnalysisProvider].
  ///
  /// If the provider is unavailable or fails for individual objects, the
  /// original on-device results are preserved.
  Future<List<DetectedObject>> _enhanceWithProvider(
    List<DetectedObject> objects,
    Map<int, FrameData> frames,
  ) async {
    final provider = _analysisProvider;
    if (provider == null) return objects;

    final isAvailable = await provider.isAvailable();
    if (!isAvailable) return objects;

    final enhanced = <DetectedObject>[];

    for (final obj in objects) {
      try {
        // Provide the full frame as context alongside the crop.
        final contextFrame = frames[obj.frameIndex]?.imageBytes;

        final result = await provider.analyzeImage(
          imageBytes: obj.croppedImage,
          contextFrame: contextFrame,
          existingLabel: obj.label,
        );

        enhanced.add(
          obj.copyWith(
            enhancedName: result.itemName,
            brand: result.brand,
            model: result.model,
            description: result.description,
            estimatedPrice: result.estimatedPrice,
            category: result.category,
          ),
        );
      } catch (_) {
        // Keep original on-device result on LLM failure.
        enhanced.add(obj);
      }
    }

    return enhanced;
  }

  /// The most recent [AnalysisSession] state. Updated throughout the pipeline.
  AnalysisSession? _lastSession;

  /// Returns the current or most recent [AnalysisSession].
  AnalysisSession? get lastSession => _lastSession;

  /// Builds an [AnalysisProgress] for the current pipeline state.
  AnalysisProgress _progress({
    required String stage,
    int currentFrame = 0,
    int totalFrames = 0,
    int itemsDetected = 0,
  }) {
    final progress = totalFrames > 0
        ? (currentFrame / totalFrames).clamp(0.0, 1.0)
        : 0.0;

    return AnalysisProgress(
      currentFrame: currentFrame,
      totalFrames: totalFrames,
      itemsDetected: itemsDetected,
      stage: stage,
      progress: progress,
    );
  }
}

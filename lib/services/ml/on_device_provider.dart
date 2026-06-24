import 'dart:typed_data';

import 'package:still_life/services/ml/analysis_provider.dart';

/// Tier 1: On-device ML provider using TFLite (YOLO + MobileNet).
///
/// This provider coordinates on-device inference. The actual TFLite calls
/// are stubbed for now — the real inference wrappers will live in the
/// pipeline services. This provider is always available (offline-capable).
class OnDeviceProvider implements AnalysisProvider {
  @override
  String get name => 'On-Device ML';

  @override
  AnalysisTier get tier => AnalysisTier.onDevice;

  /// On-device ML is always available — no network required.
  @override
  Future<bool> isAvailable() async => true;

  /// Runs YOLO object detection followed by MobileNet classification.
  ///
  /// Currently stubbed — returns a placeholder result until the TFLite
  /// inference wrappers are wired up.
  @override
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  }) async {
    // TFLite inference is not yet implemented; returns a placeholder result.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final label = existingLabel ?? 'Unknown Item';

    return AnalysisResult(
      itemName: label,
      description: 'Detected by on-device ML (stub)',
      category: 'Uncategorized',
      confidence: existingLabel != null ? 0.6 : 0.3,
      rawResponse: {
        'provider': 'on_device',
        'detections': <Map<String, dynamic>>[],
        'stub': true,
      },
    );
  }

  /// Delegates video analysis to the orchestrator pipeline.
  ///
  /// The on-device provider participates in video analysis through the
  /// orchestrator's frame-by-frame pipeline rather than handling it directly.
  @override
  Stream<AnalysisProgress> analyzeVideo({
    required String videoPath,
    required AnalysisConfig config,
  }) async* {
    // The on-device provider processes individual frames via analyzeImage.
    // Full video analysis is coordinated by the analysis orchestrator which
    // handles frame extraction, blur detection, object tracking, and
    // dispatching individual frames to this provider.
    throw UnsupportedError(
      'On-device provider does not handle video directly. '
      'Use the analysis orchestrator for video analysis.',
    );
  }
}

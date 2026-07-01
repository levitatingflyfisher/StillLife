import 'dart:typed_data';

import 'package:still_life/services/ml/analysis_provider.dart';

/// One on-device inference engine behind the Tier-1 [AnalysisTier.onDevice]
/// seam. The tier holds several engines in quality order (Gemini Nano >
/// SmolVLM2 > ML Kit labeler) and serves each call with the first engine
/// that reports itself available — flagship devices get VLM-grade output,
/// every other Android device still gets the bundled labeler floor.
///
/// Engines are image-only by design: the on-device tier advertises
/// [AnalysisCapability.image] and nothing else, so the cascade never
/// routes text or multi-item calls here.
abstract class OnDeviceEngine {
  /// Stable identifier used in settings/telemetry ('nano', 'smolvlm',
  /// 'labeler').
  String get id;

  /// Human-readable name for settings UI ("Gemini Nano", "SmolVLM2", …).
  String get displayName;

  /// Whether this engine can serve a call right now (model present,
  /// device supported). Must be honest — an available engine that then
  /// throws breaks the tier for the whole call.
  Future<bool> isAvailable();

  /// Identify the single item in [imageBytes]. [existingLabel] is a label
  /// the user already assigned — engines fold it into their prompt (or
  /// ignore it, for classic classifiers).
  Future<AnalysisResult> analyzeImage(
    Uint8List imageBytes, {
    String? existingLabel,
  });
}

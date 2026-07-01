import 'dart:typed_data';

import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/on_device/on_device_engine.dart';

/// Tier 1: on-device inference, served by a cascade of [OnDeviceEngine]s
/// in quality order (Gemini Nano > SmolVLM2 > ML Kit labeler). The first
/// engine that reports itself available handles the call.
///
/// Image-only by design — [capabilities] advertises just
/// [AnalysisCapability.image], so the ProviderManager never routes text
/// (receipt structuring, voice intake) or multi-item shelf calls here.
///
/// With no engines (the web build, or nothing wired) the tier honestly
/// reports itself unavailable and throws instead of fabricating results.
class OnDeviceProvider extends AnalysisProvider {
  final List<OnDeviceEngine> engines;

  OnDeviceProvider({this.engines = const []});

  @override
  String get name => 'On-Device ML';

  @override
  AnalysisTier get tier => AnalysisTier.onDevice;

  @override
  Set<AnalysisCapability> get capabilities => const {
    AnalysisCapability.image,
  };

  @override
  Future<bool> isAvailable() async {
    for (final engine in engines) {
      if (await engine.isAvailable()) return true;
    }
    return false;
  }

  @override
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  }) async {
    for (final engine in engines) {
      if (await engine.isAvailable()) {
        return engine.analyzeImage(imageBytes, existingLabel: existingLabel);
      }
    }
    throw StateError(
      'No on-device engine is available. '
      'OnDeviceProvider.isAvailable() is false; use another tier.',
    );
  }

  /// Not supported — the on-device tier has no text model and says so via
  /// [capabilities]. Throws instead of fabricating a result if called
  /// directly.
  @override
  Future<AnalysisResult> analyzeText(
    String prompt, {
    AnalysisContext? context,
  }) async {
    throw StateError(
      'The on-device tier is image-only (capabilities excludes text).',
    );
  }

  /// Not supported — see [analyzeText].
  @override
  Future<String> completeText(String prompt, {int maxTokens = 1000}) async {
    throw StateError(
      'The on-device tier is image-only (capabilities excludes text).',
    );
  }

  /// Not supported — multi-item detection is not part of rungs 1/1.5/2.
  /// [capabilities] excludes imageMulti so the cascade never lands here.
  @override
  Future<List<AnalysisResult>> analyzeImageMulti(
    Uint8List imageBytes, {
    AnalysisContext? context,
  }) async {
    throw StateError(
      'The on-device tier does not do multi-item analysis '
      '(capabilities excludes imageMulti).',
    );
  }
}

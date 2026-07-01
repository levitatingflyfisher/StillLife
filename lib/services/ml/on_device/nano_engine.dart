import 'dart:typed_data';

import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/on_device/on_device_engine.dart';
import 'package:still_life/services/ml/single_item_parser.dart';

/// AICore feature state for Gemini Nano on this device.
enum NanoStatus {
  /// Device has no AICore / Gemini Nano support (the common case —
  /// Pixel 9/10 and S25/S26-class flagships only).
  unsupported,

  /// Supported, but the system model needs a one-time provisioning the
  /// user must request from settings ([NanoGateway.requestSetup]) —
  /// nothing downloads without that explicit action.
  downloadable,

  /// Provisioning in progress.
  downloading,

  /// Ready for inference.
  available,
}

/// The ML Kit GenAI Prompt API (Gemini Nano via AICore). Injected so the
/// engine's logic runs in unit tests without the Beta native plugin.
abstract class NanoGateway {
  Future<NanoStatus> checkStatus();

  /// Asks AICore to provision the shared system model. Only settings
  /// calls this, always from an explicit user tap.
  Future<void> requestSetup();

  /// Runs one image+prompt inference and returns the raw model text.
  Future<String> promptWithImage({
    required String prompt,
    required Uint8List imageBytes,
  });
}

/// Rung 2: Gemini Nano through AICore — free, fully on-device inference
/// on the few devices that have it. Beta with no SLA, so it sits behind
/// the same engine seam as everything else: if Google breaks or removes
/// it, deleting this engine is the whole rollback.
///
/// `downloadable` is NOT available: provisioning is a user action in
/// settings, never a side effect of analyzing a photo.
class NanoEngine implements OnDeviceEngine {
  final NanoGateway gateway;

  NanoEngine({required this.gateway});

  @override
  String get id => 'nano';

  @override
  String get displayName => 'Gemini Nano (AICore)';

  @override
  Future<bool> isAvailable() async =>
      await gateway.checkStatus() == NanoStatus.available;

  @override
  Future<AnalysisResult> analyzeImage(
    Uint8List imageBytes, {
    String? existingLabel,
  }) async {
    final prompt = existingLabel != null
        ? 'This item has been labeled "$existingLabel". '
              '$kSingleItemAnalysisPrompt'
        : kSingleItemAnalysisPrompt;

    final reply = await gateway.promptWithImage(
      prompt: prompt,
      imageBytes: imageBytes,
    );

    return parseSingleItemResponse(reply, confidence: 0.75);
  }
}

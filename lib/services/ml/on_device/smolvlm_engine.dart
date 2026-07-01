import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/on_device/model_store_io.dart';
import 'package:still_life/services/ml/on_device/on_device_engine.dart';
import 'package:still_life/services/ml/single_item_parser.dart';

/// The native VLM runtime (llama.cpp mtmd via llama_cpp_dart). Injected so
/// the engine's logic runs in unit tests without the native library.
abstract class VlmGateway {
  /// Whether the native runtime can load on this device (library present,
  /// platform supported).
  Future<bool> runtimeAvailable();

  /// Runs one image+prompt completion and returns the raw model text.
  Future<String> describeImage({
    required String modelPath,
    required String mmprojPath,
    required String prompt,
    required Uint8List imageBytes,
  });
}

/// Shrinks a photo so its longest side is at most [maxSide] before it hits
/// the VLM — prompt-processing time on a phone CPU scales with image
/// patches, and a 12 MP photo carries no extra signal for "what item is
/// this". Small images pass through untouched; undecodable bytes pass
/// through too (the native decoder gets its own chance).
Uint8List prepareImageForVlm(Uint8List bytes, {int maxSide = 768}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  if (decoded.width <= maxSide && decoded.height <= maxSide) return bytes;
  final resized = img.copyResize(
    decoded,
    width: decoded.width >= decoded.height ? maxSide : null,
    height: decoded.height > decoded.width ? maxSide : null,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
}

/// Rung 1.5: a downloaded SmolVLM2 GGUF running fully offline through
/// llama.cpp. Available only when the native runtime loads AND the user
/// has explicitly downloaded a model (opt-in, verified by the store).
/// Sends the same single-item JSON prompt as the cloud tiers and parses
/// with the shared parser — confidence 0.6, between cloud VLMs (0.85)
/// and the raw-text fallback (0.4).
class SmolVlmEngine implements OnDeviceEngine {
  final VlmGateway gateway;
  final IoOnDeviceModelStore store;

  SmolVlmEngine({required this.gateway, required this.store});

  @override
  String get id => 'smolvlm';

  @override
  String get displayName => 'SmolVLM2 (downloaded model)';

  @override
  Future<bool> isAvailable() async {
    if (!await gateway.runtimeAvailable()) return false;
    return await store.firstDownloaded() != null;
  }

  @override
  Future<AnalysisResult> analyzeImage(
    Uint8List imageBytes, {
    String? existingLabel,
  }) async {
    final model = await store.firstDownloaded();
    if (model == null) {
      throw StateError(
        'No on-device VLM model is downloaded. '
        'SmolVlmEngine.isAvailable() is false; use another engine.',
      );
    }

    final prompt = existingLabel != null
        ? 'This item has been labeled "$existingLabel". '
              '$kSingleItemAnalysisPrompt'
        : kSingleItemAnalysisPrompt;

    final reply = await gateway.describeImage(
      modelPath: await store.filePath(model, model.textModelFile),
      mmprojPath: await store.filePath(model, model.mmprojFile),
      prompt: prompt,
      // Decode+resize of a many-MP JPEG is CPU work — off the UI isolate,
      // same as the providers' base64 encodes.
      imageBytes: await compute(prepareImageForVlm, imageBytes),
    );

    return parseSingleItemResponse(reply, confidence: 0.6);
  }
}

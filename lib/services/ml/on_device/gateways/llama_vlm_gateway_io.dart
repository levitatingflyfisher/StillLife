import 'dart:io';
import 'dart:typed_data';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:still_life/services/ml/on_device/smolvlm_engine.dart';

/// Real llama.cpp (mtmd) bridge for [SmolVlmEngine]. Thin by design.
///
/// The engine isolate stays loaded between calls: a cataloguing session
/// analyzes many photos in a row, and re-loading a ~1.1 GB GGUF per photo
/// would dwarf inference time. The trade-off (model RAM held until the OS
/// reclaims the app) is documented in the settings copy. A different
/// downloaded model triggers a respawn.
///
/// The native library ships as `libllama.so` inside the llama-cpp-dart
/// AAR (android/app/libs/); a device where it fails to load marks the
/// runtime broken so the on-device cascade falls through to the labeler
/// instead of failing every analysis.
class LlamaVlmGateway implements VlmGateway {
  LlamaEngine? _engine;
  String? _loadedModelPath;
  bool _runtimeBroken = false;

  @override
  Future<bool> runtimeAvailable() async =>
      Platform.isAndroid && !_runtimeBroken;

  @override
  Future<String> describeImage({
    required String modelPath,
    required String mmprojPath,
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    final engine = await _engineFor(modelPath, mmprojPath);

    final chat = await engine.createChat();
    try {
      chat.addUser(prompt, media: [LlamaMedia.imageBytes(imageBytes)]);
      final buffer = StringBuffer();
      await for (final event in chat.generate(maxTokens: 512)) {
        if (event is TokenEvent) buffer.write(event.text);
      }
      return buffer.toString();
    } finally {
      await chat.dispose();
    }
  }

  Future<LlamaEngine> _engineFor(String modelPath, String mmprojPath) async {
    final existing = _engine;
    if (existing != null && _loadedModelPath == modelPath) return existing;

    if (existing != null) {
      await existing.dispose();
      _engine = null;
      _loadedModelPath = null;
    }

    try {
      final engine = await LlamaEngine.spawn(
        libraryPath: 'libllama.so',
        modelParams: ModelParams(path: modelPath),
        contextParams: const ContextParams(nCtx: 4096),
        multimodalParams: MultimodalParams(
          mmprojPath: mmprojPath,
          // CPU AAR: no GPU backend to offload the projector to.
          useGpu: false,
        ),
      );
      _engine = engine;
      _loadedModelPath = modelPath;
      return engine;
    } catch (e) {
      // dlopen/spawn failure is a device/runtime problem, not a photo
      // problem — stop advertising availability so the cascade falls
      // through to the labeler on the next call.
      _runtimeBroken = true;
      rethrow;
    }
  }
}

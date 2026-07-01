import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_genai_prompt/google_mlkit_genai_prompt.dart';
// The package (0.2.0) exports only Prompt and forgets the FeatureStatus
// enum its own checkFeatureStatus() returns — reach into src for it.
// ignore: implementation_imports
import 'package:google_mlkit_genai_prompt/src/prompt.dart'
    show FeatureStatus;
import 'package:path_provider/path_provider.dart';
import 'package:still_life/services/ml/on_device/nano_engine.dart';

/// Real AICore/Gemini Nano bridge for [NanoEngine]. Thin by design.
///
/// The plugin is Beta with no SLA; every call creates and closes its own
/// [Prompt] session so a wedged native session can't poison later calls.
class AicoreNanoGateway implements NanoGateway {
  @override
  Future<NanoStatus> checkStatus() async {
    if (!Platform.isAndroid) return NanoStatus.unsupported;
    try {
      final prompt = Prompt();
      try {
        return switch (await prompt.checkFeatureStatus()) {
          FeatureStatus.available => NanoStatus.available,
          FeatureStatus.downloadable => NanoStatus.downloadable,
          FeatureStatus.downloading => NanoStatus.downloading,
          FeatureStatus.unavailable => NanoStatus.unsupported,
        };
      } finally {
        await prompt.close();
      }
    } catch (_) {
      // A missing AICore service surfaces as a channel error — that IS
      // "unsupported", not a crash.
      return NanoStatus.unsupported;
    }
  }

  @override
  Future<void> requestSetup() async {
    final prompt = Prompt();
    try {
      await prompt.downloadFeature();
    } finally {
      await prompt.close();
    }
  }

  @override
  Future<String> promptWithImage({
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/on_device_nano_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(imageBytes, flush: true);

    final session = Prompt();
    try {
      return await session.runInference(
        prompt,
        imageData: {'type': 'file', 'path': file.path},
      );
    } finally {
      await session.close();
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

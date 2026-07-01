import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:still_life/services/ml/on_device/labeler_engine.dart';

/// Real ML Kit call for [LabelerEngine.labelImage]. Thin by design — all
/// engine logic lives in the testable [LabelerEngine]; this just bridges
/// bytes → temp file → the bundled native labeler.
///
/// InputImage wants a file path for one-shot photos, so the bytes go to a
/// scratch file that is always deleted (same pattern as the video frame
/// extractor).
Future<List<DetectedLabel>> mlkitLabelImage(Uint8List imageBytes) async {
  final tempDir = await getTemporaryDirectory();
  final file = File(
    '${tempDir.path}/on_device_label_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(imageBytes, flush: true);

  final labeler = ImageLabeler(
    // Below 0.3 the base model emits scene noise ("Room", "Floor");
    // the engine sorts and presents top-3 anyway.
    options: ImageLabelerOptions(confidenceThreshold: 0.3),
  );
  try {
    final labels = await labeler.processImage(
      InputImage.fromFilePath(file.path),
    );
    return [
      for (final l in labels) DetectedLabel(l.label, l.confidence),
    ];
  } finally {
    await labeler.close();
    if (await file.exists()) {
      await file.delete();
    }
  }
}

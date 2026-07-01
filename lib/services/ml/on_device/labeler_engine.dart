import 'dart:typed_data';

import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/on_device/label_category_mapper.dart';
import 'package:still_life/services/ml/on_device/on_device_engine.dart';

/// One label from the on-device classifier.
class DetectedLabel {
  final String label;
  final double confidence;
  const DetectedLabel(this.label, this.confidence);
}

/// Rung 1: the ML Kit bundled image labeler (~400 generic labels, ships
/// inside the SDK — zero download, works offline from first launch).
///
/// A classic classifier, so the result is honestly coarse: top label as
/// the name, mapped category, real confidence — brand/model stay null
/// ("do not guess"), and the description carries provenance plus the
/// full label list so a later re-analysis on a richer tier (the
/// existingLabel hook) has everything this engine saw.
class LabelerEngine implements OnDeviceEngine {
  /// True only where the plugin can run (Android; never web).
  final Future<bool> Function() platformSupported;

  /// The native call — injected so the engine's logic is testable
  /// off-device. Returns labels in any order.
  final Future<List<DetectedLabel>> Function(Uint8List imageBytes) labelImage;

  LabelerEngine({required this.platformSupported, required this.labelImage});

  @override
  String get id => 'labeler';

  @override
  String get displayName => 'On-device labeler (ML Kit)';

  /// The base model is bundled in the SDK, so platform support is the
  /// only availability question.
  @override
  Future<bool> isAvailable() => platformSupported();

  @override
  Future<AnalysisResult> analyzeImage(
    Uint8List imageBytes, {
    String? existingLabel, // a classifier cannot use it — ignored
  }) async {
    final labels = [...await labelImage(imageBytes)]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final raw = {
      'engine': id,
      'labels': [
        for (final l in labels)
          {'label': l.label, 'confidence': l.confidence},
      ],
    };

    if (labels.isEmpty) {
      return AnalysisResult(
        itemName: 'Unknown Item',
        description:
            'On-device labeler found no label above its confidence '
            'threshold.',
        category: 'Other',
        confidence: 0.0,
        rawResponse: raw,
      );
    }

    final top = labels.first;
    final listed = labels
        .take(3)
        .map((l) => '${l.label} (${(l.confidence * 100).round()}%)')
        .join(', ');
    return AnalysisResult(
      itemName: top.label,
      description: 'On-device labels: $listed',
      category: categoryForMlKitLabel(top.label),
      confidence: top.confidence,
      rawResponse: raw,
    );
  }
}

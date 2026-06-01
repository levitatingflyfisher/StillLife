import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Result of classifying a cropped object image.
class ClassificationResult {
  /// The inventory category this object belongs to (e.g., "Electronics").
  final String category;

  /// The specific label for the object (e.g., "laptop").
  final String label;

  /// Confidence score in [0, 1].
  final double confidence;

  const ClassificationResult({
    required this.category,
    required this.label,
    required this.confidence,
  });

  @override
  String toString() =>
      'ClassificationResult($label -> $category, '
      '${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Wraps MobileNetV3 TFLite inference for fine-grained object classification.
///
/// Maps ImageNet-style labels to inventory categories using a configurable
/// category mapping file. Falls back gracefully if the model or mapping
/// file is unavailable.
class Classifier {
  final String _modelPath;
  final String _categoryMappingPath;

  Interpreter? _interpreter;
  List<String>? _labels;
  Map<String, String>? _categoryMapping;
  bool _initFailed = false;

  /// Creates a [Classifier].
  ///
  /// [modelPath] is the path to the MobileNetV3 TFLite model asset.
  /// [categoryMappingPath] is the path to a JSON file mapping labels to
  /// inventory categories.
  Classifier({
    required String modelPath,
    String categoryMappingPath = 'assets/ml/category_mapping.json',
  }) : _modelPath = modelPath,
       _categoryMappingPath = categoryMappingPath;

  /// Initializes the TFLite interpreter and loads the category mapping.
  ///
  /// Returns `true` if initialization succeeds, `false` otherwise.
  /// When initialization fails, [classify] returns `null`.
  Future<bool> initialize() async {
    if (_interpreter != null) return true;
    if (_initFailed) return false;

    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _labels = await _loadLabels();
      _categoryMapping = await _loadCategoryMapping();
      return true;
    } catch (e) {
      _initFailed = true;
      return false;
    }
  }

  /// Classifies a cropped object image.
  ///
  /// [imageBytes] should be the PNG or JPEG encoded bytes of the cropped
  /// object region.
  ///
  /// Returns a [ClassificationResult] with the predicted category, label, and
  /// confidence, or `null` if the model is unavailable or classification fails.
  Future<ClassificationResult?> classify(Uint8List imageBytes) async {
    if (_interpreter == null && !await initialize()) {
      return null;
    }

    try {
      return await Isolate.run(() => _runClassification(imageBytes));
    } catch (e) {
      return null;
    }
  }

  /// Runs MobileNetV3 inference on [imageBytes].
  ///
  /// Designed to run inside an [Isolate].
  ClassificationResult? _runClassification(Uint8List imageBytes) {
    final interpreter = _interpreter;
    final labels = _labels;
    if (interpreter == null || labels == null) return null;

    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    // MobileNetV3 expects 224x224 input.
    const inputSize = 224;
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Build input tensor [1, 224, 224, 3] normalized to [0, 1].
    final input = Float32List(1 * inputSize * inputSize * 3);
    var idx = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[idx++] = pixel.r / 255.0;
        input[idx++] = pixel.g / 255.0;
        input[idx++] = pixel.b / 255.0;
      }
    }

    final inputTensor = input.reshape([1, inputSize, inputSize, 3]);

    // Output: [1, numClasses] probability distribution.
    final numClasses = labels.length;
    final output = List.generate(1, (_) => Float32List(numClasses));

    interpreter.run(inputTensor, output);

    // Find top prediction.
    final scores = output[0];
    var bestIdx = 0;
    var bestScore = scores[0];
    for (var i = 1; i < numClasses; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIdx = i;
      }
    }

    if (bestIdx >= labels.length) return null;

    final label = labels[bestIdx];
    final category = _mapToCategory(label);

    return ClassificationResult(
      category: category,
      label: label,
      confidence: bestScore.clamp(0.0, 1.0),
    );
  }

  /// Maps a classification label to an inventory category.
  ///
  /// Falls back to "Uncategorized" if no mapping exists.
  String _mapToCategory(String label) {
    if (_categoryMapping == null) return 'Uncategorized';

    // Try exact match first, then lowercase.
    return _categoryMapping![label] ??
        _categoryMapping![label.toLowerCase()] ??
        'Uncategorized';
  }

  /// Loads classification labels from the model or a bundled asset.
  Future<List<String>> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(
        'assets/ml/mobilenet_labels.txt',
      );
      return labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    } catch (_) {
      // Return a minimal fallback set if labels file is missing.
      return const [];
    }
  }

  /// Loads the category mapping JSON from assets.
  ///
  /// Expected format: `{"label_name": "Inventory Category", ...}`
  Future<Map<String, String>> _loadCategoryMapping() async {
    try {
      final jsonStr = await rootBundle.loadString(_categoryMappingPath);
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return const {};
    }
  }

  /// Releases the TFLite interpreter resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

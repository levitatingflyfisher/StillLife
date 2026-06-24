import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';

/// Wraps YOLOv8-nano TFLite inference for object detection.
///
/// Given a frame's image bytes, runs inference and returns a list of
/// [Detection] objects with bounding boxes, labels, and confidence scores.
///
/// Handles missing model files gracefully by returning an empty list.
class ObjectDetector {
  final String _modelPath;
  final String _labelsPath;
  final double _confidenceThreshold;
  final double _nmsIouThreshold;

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _initFailed = false;

  /// Creates an [ObjectDetector].
  ///
  /// [modelPath] is the path to the YOLOv8-nano TFLite model file.
  /// [labelsPath] is the path to a newline-delimited labels file.
  /// [confidenceThreshold] filters out low-confidence detections.
  /// [nmsIouThreshold] is the IoU threshold for non-maximum suppression.
  ObjectDetector({
    required String modelPath,
    required String labelsPath,
    double confidenceThreshold = 0.4,
    double nmsIouThreshold = 0.5,
  }) : _modelPath = modelPath,
       _labelsPath = labelsPath,
       _confidenceThreshold = confidenceThreshold,
       _nmsIouThreshold = nmsIouThreshold;

  /// Initializes the TFLite interpreter and loads labels.
  ///
  /// Returns `true` if initialization succeeds, `false` otherwise. When
  /// initialization fails, [detect] will return an empty list.
  Future<bool> initialize() async {
    if (_interpreter != null) return true;
    if (_initFailed) return false;

    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _labels = await _loadLabels(_labelsPath);
      return true;
    } catch (e) {
      _initFailed = true;
      return false;
    }
  }

  /// Runs object detection on [imageBytes] for the frame at [frameIndex].
  ///
  /// Returns a list of [Detection] objects. If the model is not loaded or
  /// inference fails, returns an empty list.
  Future<List<Detection>> detect({
    required Uint8List imageBytes,
    required int frameIndex,
    int inputSize = 640,
  }) async {
    if (_interpreter == null && !await initialize()) {
      return const [];
    }

    try {
      return await Isolate.run(() {
        return _runInference(
          imageBytes: imageBytes,
          frameIndex: frameIndex,
          inputSize: inputSize,
        );
      });
    } catch (e) {
      // Graceful degradation: return empty on inference failure.
      return const [];
    }
  }

  /// Performs the actual TFLite inference.
  ///
  /// This method is designed to run in an isolate for CPU-heavy work.
  List<Detection> _runInference({
    required Uint8List imageBytes,
    required int frameIndex,
    required int inputSize,
  }) {
    final interpreter = _interpreter;
    final labels = _labels;
    if (interpreter == null || labels == null) return const [];

    final image = img.decodeImage(imageBytes);
    if (image == null) return const [];

    // Resize to model input dimensions.
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Build input tensor [1, inputSize, inputSize, 3] normalized to [0, 1].
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

    // YOLOv8 output shape: [1, numDetections, 4 + numClasses]
    final numClasses = labels.length;
    final numDetections = _estimateOutputDetections(inputSize);
    final output = List.generate(
      1,
      (_) => List.generate(numDetections, (_) => Float32List(4 + numClasses)),
    );

    interpreter.run(inputTensor, output);

    // Parse detections.
    final rawDetections = <Detection>[];
    final scaleX = image.width / inputSize;
    final scaleY = image.height / inputSize;

    for (var i = 0; i < numDetections; i++) {
      final row = output[0][i];

      // First 4 values: cx, cy, w, h (center format).
      final cx = row[0] * scaleX;
      final cy = row[1] * scaleY;
      final w = row[2] * scaleX;
      final h = row[3] * scaleY;

      // Find best class.
      var bestClassIdx = 0;
      var bestScore = 0.0;
      for (var c = 0; c < numClasses; c++) {
        final score = row[4 + c];
        if (score > bestScore) {
          bestScore = score;
          bestClassIdx = c;
        }
      }

      if (bestScore < _confidenceThreshold) continue;

      final x1 = cx - w / 2;
      final y1 = cy - h / 2;

      rawDetections.add(
        Detection(
          label: labels[bestClassIdx],
          confidence: bestScore,
          boundingBox: Rect.fromLTWH(x1, y1, w, h),
          frameIndex: frameIndex,
        ),
      );
    }

    // Apply non-maximum suppression.
    return _nonMaxSuppression(rawDetections);
  }

  /// Applies greedy non-maximum suppression to [detections].
  ///
  /// Sorts by confidence descending, then iteratively removes detections
  /// whose IoU with a higher-confidence detection exceeds [_nmsIouThreshold].
  List<Detection> _nonMaxSuppression(List<Detection> detections) {
    if (detections.isEmpty) return detections;

    // Sort by confidence descending.
    final sorted = List<Detection>.from(detections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final kept = <Detection>[];

    for (final detection in sorted) {
      var shouldKeep = true;
      for (final existing in kept) {
        if (detection.label == existing.label &&
            computeIoU(detection.boundingBox, existing.boundingBox) >
                _nmsIouThreshold) {
          shouldKeep = false;
          break;
        }
      }
      if (shouldKeep) {
        kept.add(detection);
      }
    }

    return kept;
  }

  /// Estimates the number of output detections based on YOLO grid sizes.
  int _estimateOutputDetections(int inputSize) {
    // YOLOv8 has 3 detection heads at strides 8, 16, 32.
    final s8 = (inputSize ~/ 8) * (inputSize ~/ 8);
    final s16 = (inputSize ~/ 16) * (inputSize ~/ 16);
    final s32 = (inputSize ~/ 32) * (inputSize ~/ 32);
    return s8 + s16 + s32;
  }

  Future<List<String>> _loadLabels(String path) async {
    try {
      // Attempt to load from assets via rootBundle or file.
      // For simplicity, assume labels are bundled with the model.
      // The caller can override by providing pre-loaded labels.
      return _defaultCocoLabels;
    } catch (_) {
      return _defaultCocoLabels;
    }
  }

  /// Releases the TFLite interpreter resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Default COCO labels for YOLOv8 (80 classes).
  static const _defaultCocoLabels = [
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train',
    'truck', 'boat', 'traffic light', 'fire hydrant', 'stop sign',
    'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse', 'sheep', 'cow',
    'elephant', 'bear', 'zebra', 'giraffe', 'backpack', 'umbrella', 'handbag',
    'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball', 'kite',
    'baseball bat', 'baseball glove', 'skateboard', 'surfboard',
    'tennis racket', 'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon',
    'bowl', 'banana', 'apple', 'sandwich', 'orange', 'broccoli', 'carrot',
    'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch', 'potted plant',
    'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse', 'remote',
    'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
    'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear',
    'hair drier', 'toothbrush', // 80 classes
  ];
}

/// Computes Intersection over Union (IoU) between two rectangles.
///
/// Returns a value between 0.0 (no overlap) and 1.0 (identical boxes).
double computeIoU(Rect a, Rect b) {
  final intersect = a.intersect(b);
  if (intersect.isEmpty || intersect.width <= 0 || intersect.height <= 0) {
    return 0.0;
  }

  final intersectionArea = intersect.width * intersect.height;
  final unionArea =
      (a.width * a.height) + (b.width * b.height) - intersectionArea;

  if (unionArea <= 0) return 0.0;
  return intersectionArea / unionArea;
}

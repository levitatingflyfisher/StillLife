import 'dart:typed_data';
import 'dart:ui';

import 'package:equatable/equatable.dart';

/// A single object detected in one video frame.
class Detection {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final int frameIndex;

  const Detection({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.frameIndex,
  });

  double get area => boundingBox.width * boundingBox.height;

  @override
  String toString() =>
      'Detection($label ${(confidence * 100).toStringAsFixed(0)}% '
      'frame:$frameIndex)';
}

/// A unique object tracked across multiple frames.
class TrackedObject {
  final String id;
  final List<Detection> detections;
  final int bestFrameIndex;
  final Rect bestBoundingBox;

  const TrackedObject({
    required this.id,
    required this.detections,
    required this.bestFrameIndex,
    required this.bestBoundingBox,
  });

  String get label => detections.first.label;
  double get maxConfidence =>
      detections.map((d) => d.confidence).reduce((a, b) => a > b ? a : b);
  int get frameCount => detections.length;
}

/// A fully analyzed and enriched detected object ready for user review.
class DetectedObject extends Equatable {
  final String id;
  final String label;
  final double confidence;
  final Rect boundingBox;
  final Uint8List croppedImage;
  final int frameIndex;

  // Enriched fields (from classification or LLM)
  final String? enhancedName;
  final String? brand;
  final String? model;
  final String? description;
  final double? estimatedPrice;
  final String? category;

  const DetectedObject({
    required this.id,
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.croppedImage,
    required this.frameIndex,
    this.enhancedName,
    this.brand,
    this.model,
    this.description,
    this.estimatedPrice,
    this.category,
  });

  String get displayName => enhancedName ?? label;

  DetectedObject copyWith({
    String? enhancedName,
    String? brand,
    String? model,
    String? description,
    double? estimatedPrice,
    String? category,
  }) {
    return DetectedObject(
      id: id,
      label: label,
      confidence: confidence,
      boundingBox: boundingBox,
      croppedImage: croppedImage,
      frameIndex: frameIndex,
      enhancedName: enhancedName ?? this.enhancedName,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      description: description ?? this.description,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [id];
}

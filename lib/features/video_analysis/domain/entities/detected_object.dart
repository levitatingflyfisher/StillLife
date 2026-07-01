import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// An item a vision-language model identified in a video walkthrough,
/// ready for user review.
///
/// [frameImage] is the FULL source frame the item was spotted in — the
/// same honest no-fake-cropping stance as shelf review — and is what gets
/// attached to the saved item as its `videoFrame` photo.
class DetectedObject extends Equatable {
  final String id;
  final String label;
  final double confidence;
  final Uint8List frameImage;
  final int frameIndex;

  // Enriched fields (from the VLM)
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
    required this.frameImage,
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
      frameImage: frameImage,
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

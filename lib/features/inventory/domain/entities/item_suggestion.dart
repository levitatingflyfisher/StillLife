import 'dart:typed_data';

/// Structured suggestion returned by photo or voice analysis.
/// All fields nullable — partial suggestions are valid.
///
/// Domain entities should not depend on image_picker (a presentation-layer
/// package). The captured photo travels as raw [photoBytes] — the only form
/// that works on every platform (web XFiles have no usable filesystem path)
/// and the form the BLOB-backed photo store consumes. [photoPath] is kept
/// for display/debugging alongside.
class ItemSuggestion {
  final String? name;
  final String? brand;
  final String? model;
  final String? categoryName; // plain name, not ID — matched by name in form
  final double? estimatedValue;
  final String? notes;
  final String? photoPath;
  final Uint8List? photoBytes;

  /// Model confidence in this suggestion, 0..1. Shown on the shelf-review
  /// screen so the user can judge which suggestions to trust; null when
  /// the source path does not report one.
  final double? confidence;

  const ItemSuggestion({
    this.name,
    this.brand,
    this.model,
    this.categoryName,
    this.estimatedValue,
    this.notes,
    this.photoPath,
    this.photoBytes,
    this.confidence,
  });

  ItemSuggestion copyWith({
    String? name,
    String? brand,
    String? model,
    String? categoryName,
    double? estimatedValue,
    String? notes,
    String? photoPath,
    Uint8List? photoBytes,
    double? confidence,
  }) {
    return ItemSuggestion(
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      categoryName: categoryName ?? this.categoryName,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      photoBytes: photoBytes ?? this.photoBytes,
      confidence: confidence ?? this.confidence,
    );
  }
}

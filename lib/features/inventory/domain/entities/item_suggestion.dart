/// Structured suggestion returned by photo or voice analysis.
/// All fields nullable — partial suggestions are valid.
///
/// Domain entities should not depend on image_picker (a presentation-layer
/// package). We carry the picked photo by file path string instead and
/// let the presentation layer reconstruct an XFile on demand.
class ItemSuggestion {
  final String? name;
  final String? categoryName; // plain name, not ID — matched by name in form
  final double? estimatedValue;
  final String? notes;
  final String? photoPath;

  const ItemSuggestion({
    this.name,
    this.categoryName,
    this.estimatedValue,
    this.notes,
    this.photoPath,
  });

  ItemSuggestion copyWith({
    String? name,
    String? categoryName,
    double? estimatedValue,
    String? notes,
    String? photoPath,
  }) {
    return ItemSuggestion(
      name: name ?? this.name,
      categoryName: categoryName ?? this.categoryName,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

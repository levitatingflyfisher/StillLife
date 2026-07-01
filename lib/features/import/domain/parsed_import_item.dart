/// Source of an imported item batch.
enum ImportSource { receipt, amazonCsv, amazonText, bankCsv }

/// An item parsed from an external import source (receipt, Amazon order, bank CSV).
///
/// This is a pure data class — no persistence, no business logic.
class ParsedImportItem {
  final String name;
  final double? price;
  final DateTime? purchaseDate;
  final String? categoryHint;
  final String? storeName;
  final String? asin;

  /// Product identity, filled only when the source printed it (the LLM
  /// receipt-structuring stage is told not to guess).
  final String? brand;
  final String? model;

  /// Free-text carried onto the created item's notes (e.g. "Qty: 3" when an
  /// Amazon order line covers more than one unit).
  final String? notes;
  final ImportSource source;

  const ParsedImportItem({
    required this.name,
    this.price,
    this.purchaseDate,
    this.categoryHint,
    this.storeName,
    this.asin,
    this.brand,
    this.model,
    this.notes,
    required this.source,
  });
}

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
  final ImportSource source;

  const ParsedImportItem({
    required this.name,
    this.price,
    this.purchaseDate,
    this.categoryHint,
    this.storeName,
    this.asin,
    required this.source,
  });
}

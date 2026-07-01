import 'dart:typed_data';

import 'import_review_item.dart';

/// Route arguments for the import review screen: the items to review plus
/// (for receipt-sourced imports) the receipt-level context.
class ImportReviewArgs {
  final List<ImportReviewItem> items;
  final ImportReviewReceipt? receipt;

  const ImportReviewArgs({required this.items, this.receipt});
}

/// Receipt-level context riding alongside a receipt-sourced import: the
/// engine label shown in review, plus everything needed to persist one
/// Receipts row when the user accepts the import.
class ImportReviewReceipt {
  /// Which engine produced the parse, e.g. `AI-structured (Cloud API)` or
  /// `Pattern-matched` — the user deserves to know.
  final String engineLabel;
  final String? storeName;
  final DateTime? purchaseDate;
  final double? totalAmount;
  final String ocrText;
  final Uint8List? imageBytes;

  const ImportReviewReceipt({
    required this.engineLabel,
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    required this.ocrText,
    this.imageBytes,
  });
}

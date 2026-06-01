/// Parsed data extracted from raw OCR text of a receipt.
class ReceiptParseResult {
  final String? storeName;
  final String? date;
  final String? total;
  final List<ReceiptLineItem> lineItems;

  const ReceiptParseResult({
    this.storeName,
    this.date,
    this.total,
    required this.lineItems,
  });
}

class ReceiptLineItem {
  final String name;
  final String price;

  const ReceiptLineItem({required this.name, required this.price});
}

/// Pure, stateless OCR text parser for receipts.
///
/// Heuristics:
/// - Store name: first non-empty line
/// - Date: first token matching MM/DD/YYYY or YYYY-MM-DD patterns
/// - Total: first line containing the word "total" and a dollar amount;
///          falls back to the last price-looking token in the text
/// - Line items: lines with a trailing price that aren't skipped keywords
class ReceiptParser {
  const ReceiptParser();

  static final _dateRe = RegExp(
    r'(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4})|(\d{4}[/\-]\d{2}[/\-]\d{2})',
  );
  static final _totalRe = RegExp(
    r'total[^\d]*(\$?\s*\d+[.,]\d{2})',
    caseSensitive: false,
  );
  static final _priceRe = RegExp(r'\$?\s*\d+[.,]\d{2}');
  static final _itemPriceRe = RegExp(r'^(.+?)\s+(\$?\s*\d+[.,]\d{2})\s*$');
  static final _skipWords = RegExp(
    r'(total|subtotal|tax|tip|change|balance)',
    caseSensitive: false,
  );

  ReceiptParseResult parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? storeName;
    String? date;
    String? total;
    final lineItems = <ReceiptLineItem>[];

    if (lines.isNotEmpty) storeName = lines.first;

    for (final line in lines) {
      final m = _dateRe.firstMatch(line);
      if (m != null) {
        date = m.group(0);
        break;
      }
    }

    for (final line in lines) {
      final m = _totalRe.firstMatch(line);
      if (m != null) {
        total = m.group(1);
        break;
      }
    }
    if (total == null) {
      for (final line in lines.reversed) {
        if (_priceRe.hasMatch(line)) {
          total = _priceRe.firstMatch(line)!.group(0);
          break;
        }
      }
    }

    for (final line in lines) {
      final m = _itemPriceRe.firstMatch(line);
      if (m != null && !_skipWords.hasMatch(line)) {
        lineItems.add(
          ReceiptLineItem(name: m.group(1)!.trim(), price: m.group(2)!.trim()),
        );
      }
    }

    return ReceiptParseResult(
      storeName: storeName,
      date: date,
      total: total,
      lineItems: lineItems,
    );
  }
}

/// The ONE deterministic receipt-text parser.
///
/// Consolidates what used to be three near-duplicate parsers:
/// the live-but-crude regex stage of `ImportReceiptOcrService` (name+price
/// only), `features/scanning`'s display-only demo parser (store/date/total
/// as strings), and `features/store_integration`'s dead-code service (typed
/// fields + rawText). This keeps the best of each: store-name heuristics,
/// typed [DateTime] dates, a negative-lookbehind total (so "Subtotal" can
/// never win), typed line-item prices, and the raw OCR text retained.
library;

/// Parsed data extracted from raw OCR text of a receipt.
class ReceiptParseResult {
  final String? storeName;
  final DateTime? purchaseDate;
  final double? totalAmount;
  final List<ReceiptLineItem> lineItems;
  final String rawText;

  const ReceiptParseResult({
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    this.lineItems = const [],
    required this.rawText,
  });
}

class ReceiptLineItem {
  final String name;
  final double? price;

  const ReceiptLineItem({required this.name, this.price});
}

/// Pure, stateless OCR-text parser for receipts.
///
/// Heuristics:
/// - Store name: first of the top three lines that isn't a price, date, or
///   total line.
/// - Date: first token matching MM/DD/YYYY, YYYY-MM-DD, or MM/DD/YY;
///   impossible values (month 13) are skipped, not thrown.
/// - Total: last line containing a total keyword ("total" guarded by a
///   negative lookbehind so "Subtotal" cannot match, "amount due",
///   "balance") with a price on it; falls back to the last price-looking
///   token in the text.
/// - Line items: lines with a trailing price whose name contains at least
///   one letter and isn't a skip keyword (totals, tax, tender lines).
class ReceiptParser {
  const ReceiptParser();

  static final _datePatterns = [
    // MM/DD/YYYY or MM-DD-YYYY
    RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
    // YYYY-MM-DD
    RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
    // MM/DD/YY
    RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2})\b'),
  ];

  /// Negative lookbehind so "Subtotal" (…b·total) can't match — the loop
  /// would otherwise take a subtotal line as the total.
  static final _totalKeyword = RegExp(
    r'(?<![a-zA-Z])(total|amount\s*due|balance)',
    caseSensitive: false,
  );
  static final _price = RegExp(r'\$?\s*(\d[\d,]*[.,]\d{2})');
  static final _trailingPrice = RegExp(r'^(.+?)\s+\$?\s*(\d[\d,]*[.,]\d{2})\s*$');
  static final _hasLetter = RegExp(r'[A-Za-z]');
  /// Tender/total lines START with the keyword; the trailing lookahead
  /// stops mid-word hits ("SIRLOIN TIP", "TAXI", "CASHEW", "IMPROVISATION")
  /// from silently dropping real items.
  static final _skipWords = RegExp(
    r'^\s*(total|subtotal|tax|tip|change|cash|credit|debit|balance'
    r'|amount\s*due|visa|mastercard|amex|discover)(?![a-zA-Z])',
    caseSensitive: false,
  );

  ReceiptParseResult parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return ReceiptParseResult(
      storeName: _extractStoreName(lines),
      purchaseDate: _extractDate(lines),
      totalAmount: _extractTotal(lines),
      lineItems: _extractLineItems(lines),
      rawText: text,
    );
  }

  String? _extractStoreName(List<String> lines) {
    for (final line in lines.take(3)) {
      if (!_price.hasMatch(line) &&
          !_totalKeyword.hasMatch(line) &&
          !_datePatterns.any((p) => p.hasMatch(line))) {
        return line;
      }
    }
    return null;
  }

  DateTime? _extractDate(List<String> lines) {
    for (final line in lines) {
      for (var i = 0; i < _datePatterns.length; i++) {
        final match = _datePatterns[i].firstMatch(line);
        if (match == null) continue;
        final date = switch (i) {
          0 => _validDate(
              int.parse(match.group(3)!),
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
            ),
          1 => _validDate(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
            ),
          _ => _validDate(
              2000 + int.parse(match.group(3)!),
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
            ),
        };
        if (date != null) return date;
      }
    }
    return null;
  }

  /// DateTime() silently rolls impossible values over (month 13 → January);
  /// reject those instead of inventing a date.
  DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    return (date.month == month && date.day == day) ? date : null;
  }

  double? _extractTotal(List<String> lines) {
    // A receipt prints its grand total near the bottom — search upward.
    for (final line in lines.reversed) {
      if (!_totalKeyword.hasMatch(line)) continue;
      final priceMatch = _price.firstMatch(line);
      if (priceMatch != null) return _parsePrice(priceMatch.group(1)!);
    }
    // No keyword anywhere: the last price-looking token is the best guess.
    for (final line in lines.reversed) {
      final priceMatch = _price.firstMatch(line);
      if (priceMatch != null) return _parsePrice(priceMatch.group(1)!);
    }
    return null;
  }

  List<ReceiptLineItem> _extractLineItems(List<String> lines) {
    final items = <ReceiptLineItem>[];
    for (final line in lines) {
      if (_skipWords.hasMatch(line)) continue;
      final match = _trailingPrice.firstMatch(line);
      if (match == null) continue;
      final name = match.group(1)!.trim();
      // A "name" without a single letter is OCR noise (quantity
      // continuation lines like "2 @", bare numbers).
      if (!_hasLetter.hasMatch(name)) continue;
      items.add(
        ReceiptLineItem(name: name, price: _parsePrice(match.group(2)!)),
      );
    }
    return items;
  }

  /// Parses a price token to a double, handling "1,299.99" (thousands
  /// separators) and "3,99" (comma decimal), rounded to cents.
  double? _parsePrice(String token) {
    final normalized = token.contains('.')
        ? token.replaceAll(',', '')
        : token.replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value == null ? null : (value * 100).roundToDouble() / 100;
  }
}

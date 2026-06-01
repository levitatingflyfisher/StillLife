import 'package:csv/csv.dart';
import 'package:html/parser.dart' as html_parser;

import '../../features/import/domain/parsed_import_item.dart';

/// Parses Amazon order exports (CSV or plain text/HTML) into [ParsedImportItem] list.
class AmazonImportService {
  /// Parses an Amazon order history CSV export.
  ///
  /// Expects a header row with columns including "Title", "Item Total",
  /// "ASIN/ISBN", and optionally "Category" and "Order Date".
  /// Rows with empty titles are skipped.
  List<ParsedImportItem> parseFromCsv(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.isEmpty) return [];

    // Build column index map from header row.
    final headers = rows.first.map((h) => h.toString().trim()).toList();
    int col(String name) =>
        headers.indexWhere((h) => h.toLowerCase() == name.toLowerCase());

    final titleIdx = col('Title');
    final priceIdx = col('Item Total');
    final asinIdx = col('ASIN/ISBN');
    final categoryIdx = col('Category');
    final dateIdx = col('Order Date');

    if (titleIdx == -1) return [];

    final items = <ParsedImportItem>[];
    for (final row in rows.skip(1)) {
      if (row.length <= titleIdx) continue;
      final name = row[titleIdx].toString().trim();
      if (name.isEmpty) continue;

      final price = priceIdx != -1
          ? _parsePrice(row[priceIdx].toString())
          : null;
      final asin = asinIdx != -1 ? row[asinIdx].toString().trim() : null;
      final categoryHint = categoryIdx != -1
          ? (row[categoryIdx].toString().trim().isEmpty
                ? null
                : row[categoryIdx].toString().trim())
          : null;
      final purchaseDate = dateIdx != -1
          ? _parseDate(row[dateIdx].toString())
          : null;

      items.add(
        ParsedImportItem(
          name: name,
          price: price,
          purchaseDate: purchaseDate,
          categoryHint: categoryHint,
          asin: asin != null && asin.isNotEmpty ? asin : null,
          source: ImportSource.amazonCsv,
        ),
      );
    }
    return items;
  }

  /// Parses Amazon order text or HTML (e.g. forwarded email body).
  ///
  /// Strips HTML tags, then extracts item/price pairs via regex.
  List<ParsedImportItem> parseFromText(String content) {
    if (content.trim().isEmpty) return [];

    // Strip HTML if present.
    final text = content.contains('<')
        ? html_parser.parse(content).body?.text ?? content
        : content;

    final items = <ParsedImportItem>[];

    // Match "Item: <name>" lines followed (within a few lines) by "Price: $xx.xx".
    final itemPattern = RegExp(r'Item:\s*(.+)', caseSensitive: false);
    final pricePattern = RegExp(
      r'Price:\s*\$?([\d,]+\.?\d*)',
      caseSensitive: false,
    );

    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final itemMatch = itemPattern.firstMatch(lines[i]);
      if (itemMatch == null) continue;

      final name = itemMatch.group(1)!.trim();
      if (name.isEmpty) continue;

      // Look ahead up to 5 lines for a price.
      double? price;
      for (int j = i + 1; j < lines.length && j <= i + 5; j++) {
        final priceMatch = pricePattern.firstMatch(lines[j]);
        if (priceMatch != null) {
          price = double.tryParse(priceMatch.group(1)!.replaceAll(',', ''));
          break;
        }
      }

      items.add(
        ParsedImportItem(
          name: name,
          price: price,
          source: ImportSource.amazonText,
        ),
      );
    }
    return items;
  }

  double? _parsePrice(String raw) {
    final cleaned = raw.trim().replaceAll(r'$', '').replaceAll(',', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  DateTime? _parseDate(String raw) {
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }
}

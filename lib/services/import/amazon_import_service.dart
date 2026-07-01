import 'package:csv/csv.dart';
import 'package:html/parser.dart' as html_parser;

import 'bank_statement_parser.dart';
import '../../features/import/domain/parsed_import_item.dart';

/// Parses Amazon order exports (CSV or plain text/HTML) into [ParsedImportItem] list.
///
/// Two CSV dialects are recognised, auto-detected from the header row
/// (case-insensitive, order-independent — the filename plays no part):
///
/// * **Legacy Order History Reports** ("Title", "Item Total", "ASIN/ISBN",
///   ...) — the website facility Amazon retired in 2023. Kept so old
///   exports keep importing.
/// * **Retail.OrderHistory** ("Product Name", "Unit Price", "Total Owed",
///   ...) — the CSV inside the ZIP that Privacy Central's "Request My
///   Data" delivers today. Amazon publishes no schema for it; the column
///   set follows the community-documented format.
class AmazonImportService {
  /// Parses any Amazon order export: CSV content is detected by its header
  /// row; anything else falls through to the text/HTML email parser.
  List<ParsedImportItem> parse(String content) {
    final fromCsv = parseFromCsv(content);
    if (fromCsv.isNotEmpty) return fromCsv;
    return parseFromText(content);
  }

  /// Parses an Amazon order history CSV export (either dialect — see class
  /// doc). Returns an empty list when the header row matches neither.
  List<ParsedImportItem> parseFromCsv(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.isEmpty) return [];

    // Build column index map from header row.
    final headers = rows.first
        .map((h) => h.toString().trim().toLowerCase())
        .toList();
    int col(String name) => headers.indexOf(name.toLowerCase());

    if (col('title') != -1) return _parseLegacyRows(rows, col);
    if (col('product name') != -1) return _parseRetailRows(rows, col);
    return [];
  }

  /// Legacy Order History Reports rows (pre-2023 website export).
  List<ParsedImportItem> _parseLegacyRows(
    List<List<dynamic>> rows,
    int Function(String) col,
  ) {
    final titleIdx = col('Title');
    final priceIdx = col('Item Total');
    final asinIdx = col('ASIN/ISBN');
    final categoryIdx = col('Category');
    final dateIdx = col('Order Date');

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

  /// Retail.OrderHistory rows (Privacy Central "Request My Data" ZIP).
  ///
  /// Malformed/summary rows (too short, empty product name) are skipped.
  /// Zero-price/digital rows still import with a null price — the user
  /// deselects unwanted lines in the review screen.
  List<ParsedImportItem> _parseRetailRows(
    List<List<dynamic>> rows,
    int Function(String) col,
  ) {
    final nameIdx = col('Product Name');
    final unitPriceIdx = col('Unit Price');
    final totalOwedIdx = col('Total Owed');
    final asinIdx = col('ASIN');
    final dateIdx = col('Order Date');
    final qtyIdx = col('Quantity');

    String cell(List<dynamic> row, int idx) =>
        idx >= 0 && idx < row.length ? row[idx].toString().trim() : '';

    final items = <ParsedImportItem>[];
    for (final row in rows.skip(1)) {
      final name = cell(row, nameIdx);
      if (name.isEmpty) continue;

      // Unit Price is the per-item figure; Total Owed (includes tax and
      // shipping) is only a fallback when Unit Price is absent/unparseable.
      var price = _parsePrice(cell(row, unitPriceIdx));
      price ??= _parsePrice(cell(row, totalOwedIdx));
      // A zero total is an artifact (digital freebie, promotional credit),
      // not a price worth recording.
      if (price == 0) price = null;

      final asin = cell(row, asinIdx);
      final qty = int.tryParse(cell(row, qtyIdx));

      items.add(
        ParsedImportItem(
          name: name,
          price: price,
          purchaseDate: _parseDate(cell(row, dateIdx)),
          asin: asin.isEmpty ? null : asin,
          notes: qty != null && qty > 1 ? 'Qty: $qty' : null,
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

  DateTime? _parseDate(String raw) => parseImportDate(raw);
}

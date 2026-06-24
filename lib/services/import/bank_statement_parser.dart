import 'package:csv/csv.dart';

import '../../features/import/domain/parsed_import_item.dart';

/// Column index mapping for a bank statement CSV.
///
/// Defined here (service layer) so [BankStatementParser] is self-contained.
/// The UI imports this from the service — never from the domain layer.
class BankColumnMap {
  final int? dateCol;
  final int? descriptionCol;
  final int? amountCol;

  const BankColumnMap({this.dateCol, this.descriptionCol, this.amountCol});
}

/// Parses bank statement CSV exports into [ParsedImportItem] lists.
///
/// - Positive amounts only (negative = refund/credit = skipped).
/// - Accounting notation `(123.45)` is treated as negative = skipped.
/// - Capped at 500 data rows; [parse] result carries a [truncated] flag.
class BankStatementParser {
  static const _rowCap = 500;

  /// Heuristically detects date/description/amount column indices from
  /// the CSV header row.
  BankColumnMap detectColumns(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.isEmpty) return const BankColumnMap();

    final headers = rows.first
        .map((h) => h.toString().toLowerCase().trim())
        .toList();

    int? find(List<String> keywords) {
      for (int i = 0; i < headers.length; i++) {
        if (keywords.any((k) => headers[i].contains(k))) return i;
      }
      return null;
    }

    return BankColumnMap(
      dateCol: find(['date', 'posted', 'trans']),
      descriptionCol: find([
        'description',
        'merchant',
        'memo',
        'payee',
        'details',
      ]),
      amountCol: find(['amount', 'debit', 'charge', 'withdrawal']),
    );
  }

  /// Parses [csvContent] using the given column mapping.
  ///
  /// Returns a named record `({List<ParsedImportItem> items, bool truncated})`.
  ({List<ParsedImportItem> items, bool truncated}) parse(
    String csvContent,
    BankColumnMap map,
  ) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.length <= 1) return (items: [], truncated: false);

    final dataRows = rows.skip(1).toList();
    final truncated = dataRows.length > _rowCap;
    final capped = truncated ? dataRows.take(_rowCap) : dataRows;

    final items = <ParsedImportItem>[];
    for (final row in capped) {
      // Amount column is required.
      if (map.amountCol == null || row.length <= map.amountCol!) continue;

      final amountRaw = row[map.amountCol!].toString().trim();
      final amount = _parseAmount(amountRaw);
      if (amount == null || amount <= 0) continue;

      final name =
          map.descriptionCol != null && row.length > map.descriptionCol!
          ? row[map.descriptionCol!].toString().trim()
          : '';
      if (name.isEmpty) continue;

      final purchaseDate = map.dateCol != null && row.length > map.dateCol!
          ? _parseDate(row[map.dateCol!].toString())
          : null;

      items.add(
        ParsedImportItem(
          name: name,
          price: amount,
          purchaseDate: purchaseDate,
          source: ImportSource.bankCsv,
        ),
      );
    }

    return (items: items, truncated: truncated);
  }

  /// Returns null for negative amounts, accounting notation, or unparseable strings.
  double? _parseAmount(String raw) {
    if (raw.isEmpty) return null;
    // Accounting notation (123.45) = negative = skip.
    if (raw.startsWith('(') && raw.endsWith(')')) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^\d.\-]'), '');
    try {
      final value = double.parse(cleaned);
      return value < 0 ? null : value;
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(String raw) {
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }
}

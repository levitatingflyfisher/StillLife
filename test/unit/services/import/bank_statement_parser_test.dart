import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/import/domain/parsed_import_item.dart';
import 'package:still_life/services/import/bank_statement_parser.dart';

void main() {
  late BankStatementParser parser;

  setUp(() => parser = BankStatementParser());

  // --- BankColumnMap & detectColumns ---

  test(
    'detectColumns finds date/description/amount columns by header keywords',
    () {
      const csv = 'Date,Description,Amount\n2024-01-01,Coffee Shop,12.50\n';
      final map = parser.detectColumns(csv);
      expect(map.dateCol, 0);
      expect(map.descriptionCol, 1);
      expect(map.amountCol, 2);
    },
  );

  test('detectColumns returns null indices when columns not found', () {
    const csv = 'A,B,C\n1,2,3\n';
    final map = parser.detectColumns(csv);
    expect(map.dateCol, isNull);
    expect(map.descriptionCol, isNull);
    expect(map.amountCol, isNull);
  });

  // --- parse() ---

  test('parse returns items for positive amounts', () {
    const csv = 'Date,Description,Amount\n2024-01-15,Coffee Shop,12.50\n';
    const map = BankColumnMap(dateCol: 0, descriptionCol: 1, amountCol: 2);
    final result = parser.parse(csv, map);
    expect(result.items.length, 1);
    expect(result.items.first.name, 'Coffee Shop');
    expect(result.items.first.price, 12.50);
    expect(result.items.first.source, ImportSource.bankCsv);
  });

  test('parse skips rows with negative amounts', () {
    const csv = 'Date,Description,Amount\n2024-01-15,Refund,-5.00\n';
    const map = BankColumnMap(dateCol: 0, descriptionCol: 1, amountCol: 2);
    final result = parser.parse(csv, map);
    expect(result.items, isEmpty);
  });

  test('parse skips rows with accounting notation (123.45)', () {
    const csv = 'Date,Description,Amount\n2024-01-15,Credit,(50.00)\n';
    const map = BankColumnMap(dateCol: 0, descriptionCol: 1, amountCol: 2);
    final result = parser.parse(csv, map);
    expect(result.items, isEmpty);
  });

  test('parse skips rows with unparseable amount', () {
    const csv = 'Date,Description,Amount\n2024-01-15,Coffee,N/A\n';
    const map = BankColumnMap(dateCol: 0, descriptionCol: 1, amountCol: 2);
    final result = parser.parse(csv, map);
    expect(result.items, isEmpty);
  });

  test('parse sets purchaseDate from date column', () {
    const csv = 'Date,Description,Amount\n2024-01-15,Coffee,12.50\n';
    const map = BankColumnMap(dateCol: 0, descriptionCol: 1, amountCol: 2);
    final result = parser.parse(csv, map);
    expect(result.items.first.purchaseDate, DateTime(2024, 1, 15));
  });

  test('parse truncates at 500 rows and sets truncated=true', () {
    final rows = List.generate(502, (i) => '2024-01-01,Item $i,${i + 1}.00');
    final csv = 'Date,Description,Amount\n${rows.join('\n')}\n';
    const map = BankColumnMap(dateCol: 0, descriptionCol: 1, amountCol: 2);
    final result = parser.parse(csv, map);
    expect(result.items.length, 500);
    expect(result.truncated, isTrue);
  });

  test('parse returns truncated=false when under 500 rows', () {
    const csv = 'Date,Description,Amount\n2024-01-15,Coffee,12.50\n';
    const map = BankColumnMap(dateCol: 0, descriptionCol: 1, amountCol: 2);
    final result = parser.parse(csv, map);
    expect(result.truncated, isFalse);
  });

  test('parse handles non-USD currency prefix (£, €)', () {
    const csv =
        'Date,Description,Amount\n2024-01-15,Grocery,£12.50\n2024-01-16,Cafe,€8.00\n';
    const map = BankColumnMap(dateCol: 0, descriptionCol: 1, amountCol: 2);
    final result = parser.parse(csv, map);
    expect(result.items.length, 2);
    expect(result.items[0].price, 12.50);
    expect(result.items[1].price, 8.00);
  });
}

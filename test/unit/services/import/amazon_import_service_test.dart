import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/import/domain/parsed_import_item.dart';
import 'package:still_life/services/import/amazon_import_service.dart';

void main() {
  late AmazonImportService service;

  setUp(() => service = AmazonImportService());

  // --- CSV parsing ---

  test('parseFromCsv returns empty list for header-only input', () {
    const csv =
        '"Order Date","Order ID","Title","Category","ASIN/ISBN","Quantity","Item Total"\n';
    final items = service.parseFromCsv(csv);
    expect(items, isEmpty);
  });

  test('parseFromCsv parses name and price from standard Amazon CSV', () {
    const csv =
        '"Order Date","Order ID","Title","Category","ASIN/ISBN","Quantity","Item Total"\n'
        '"2024-01-15","123-456","Coffee Beans 1kg","Grocery","B00ABC","1","\$24.99"\n';
    final items = service.parseFromCsv(csv);
    expect(items.length, 1);
    expect(items.first.name, 'Coffee Beans 1kg');
    expect(items.first.price, 24.99);
    expect(items.first.source, ImportSource.amazonCsv);
  });

  test('parseFromCsv sets asin from ASIN/ISBN column', () {
    const csv =
        '"Order Date","Order ID","Title","Category","ASIN/ISBN","Quantity","Item Total"\n'
        '"2024-01-15","123","Widget","Electronics","B00XYZ","1","\$9.99"\n';
    final items = service.parseFromCsv(csv);
    expect(items.first.asin, 'B00XYZ');
  });

  test('parseFromCsv sets categoryHint from Category column', () {
    const csv =
        '"Order Date","Order ID","Title","Category","ASIN/ISBN","Quantity","Item Total"\n'
        '"2024-01-15","123","Widget","Electronics","B00XYZ","1","\$9.99"\n';
    final items = service.parseFromCsv(csv);
    expect(items.first.categoryHint, 'Electronics');
  });

  test('parseFromCsv handles price with no dollar sign', () {
    const csv =
        '"Order Date","Order ID","Title","Category","ASIN/ISBN","Quantity","Item Total"\n'
        '"2024-01-15","123","Widget","","B00XYZ","1","14.50"\n';
    final items = service.parseFromCsv(csv);
    expect(items.first.price, 14.50);
  });

  test('parseFromCsv includes item with unparseable price as null', () {
    const csv =
        '"Order Date","Order ID","Title","Category","ASIN/ISBN","Quantity","Item Total"\n'
        '"2024-01-15","123","Widget","","B00XYZ","1","N/A"\n';
    final items = service.parseFromCsv(csv);
    expect(items.length, 1);
    expect(items.first.price, isNull);
  });

  test('parseFromCsv skips rows with empty title', () {
    const csv =
        '"Order Date","Order ID","Title","Category","ASIN/ISBN","Quantity","Item Total"\n'
        '"2024-01-15","123","","","B00XYZ","1","\$9.99"\n';
    final items = service.parseFromCsv(csv);
    expect(items, isEmpty);
  });

  test('parseFromCsv parses multiple rows', () {
    const csv =
        '"Order Date","Order ID","Title","Category","ASIN/ISBN","Quantity","Item Total"\n'
        '"2024-01-15","123","Item A","","B001","1","\$5.00"\n'
        '"2024-01-16","456","Item B","","B002","1","\$10.00"\n';
    final items = service.parseFromCsv(csv);
    expect(items.length, 2);
    expect(items[0].name, 'Item A');
    expect(items[1].name, 'Item B');
  });

  // --- Text / HTML parsing ---

  test('parseFromText returns empty list for empty string', () {
    final items = service.parseFromText('');
    expect(items, isEmpty);
  });

  test('parseFromText extracts items from plain text order', () {
    const text = '''
Order Confirmation
Item: Stainless Steel Water Bottle
Price: \$18.95
Item: Notebook A5
Price: \$7.99
''';
    final items = service.parseFromText(text);
    expect(items.length, 2);
    expect(items[0].name, contains('Water Bottle'));
    expect(items[0].price, 18.95);
    expect(items[1].name, contains('Notebook'));
    expect(items[1].price, 7.99);
  });

  test('parseFromText sets source to amazonText', () {
    const text = 'Item: Widget\nPrice: \$5.00\n';
    final items = service.parseFromText(text);
    expect(items.first.source, ImportSource.amazonText);
  });

  test('parseFromText strips HTML tags before parsing', () {
    const html =
        '<html><body><p>Item: <b>Widget</b></p><p>Price: \$5.00</p></body></html>';
    final items = service.parseFromText(html);
    expect(items.length, 1);
    expect(items.first.name, contains('Widget'));
  });
}

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

  // --- Retail.OrderHistory (Privacy Central "Request My Data") parsing ---
  //
  // Amazon killed the legacy Order History Reports facility in 2023; the
  // only self-serve export today is the Privacy Central ZIP containing
  // Retail.OrderHistory.1.csv. Amazon publishes no schema for it, so these
  // fixtures follow the community-documented format that tools like
  // amazon-orders-to-transactions target.

  const retailHeader =
      '"Website","Order ID","Order Date","Purchase Order Number","Currency",'
      '"Unit Price","Unit Price Tax","Shipping Charge","Total Discounts",'
      '"Total Owed","Shipment Item Subtotal","Shipment Item Subtotal Tax",'
      '"ASIN","Product Condition","Quantity","Payment Instrument Type",'
      '"Order Status","Shipment Status","Ship Date","Shipping Option",'
      '"Shipping Address","Billing Address","Carrier Name & Tracking Number",'
      '"Product Name","Gift Message","Gift Sender Name",'
      '"Gift Recipient Contact Details","Item Serial Number"';

  String retailRow({
    String orderDate = '2024-01-15T20:30:15Z',
    String unitPrice = '24.99',
    String totalOwed = '27.05',
    String asin = 'B00ABC123',
    String quantity = '1',
    String productName = 'Coffee Beans 1kg',
  }) =>
      '"Amazon.com","111-2223334-5556667","$orderDate","Not Applicable",'
      '"USD","$unitPrice","2.06","0","0","$totalOwed","24.99","2.06",'
      '"$asin","New","$quantity","Visa - 1234","Closed","Shipped",'
      '"2024-01-16T08:00:00Z","standard","J Doe 1 Main St","J Doe 1 Main St",'
      '"AMZN_US(TBA123)","$productName","","","","Not Applicable"';

  group('Retail.OrderHistory CSV', () {
    test('detects the format by headers and maps Product Name and Unit Price',
        () {
      final csv = '$retailHeader\n${retailRow()}\n';
      final items = service.parseFromCsv(csv);
      expect(items.length, 1);
      expect(items.first.name, 'Coffee Beans 1kg');
      expect(items.first.price, 24.99);
      expect(items.first.source, ImportSource.amazonCsv);
    });

    test('maps ASIN and ISO Order Date', () {
      final csv = '$retailHeader\n${retailRow()}\n';
      final items = service.parseFromCsv(csv);
      expect(items.first.asin, 'B00ABC123');
      expect(items.first.purchaseDate, DateTime.parse('2024-01-15T20:30:15Z'));
    });

    test('parses US-format Order Date', () {
      final csv = '$retailHeader\n${retailRow(orderDate: '01/15/2024')}\n';
      final items = service.parseFromCsv(csv);
      expect(items.first.purchaseDate, DateTime(2024, 1, 15));
    });

    test('falls back to Total Owed when Unit Price is not parseable', () {
      final csv =
          '$retailHeader\n${retailRow(unitPrice: 'Not Available')}\n';
      final items = service.parseFromCsv(csv);
      expect(items.first.price, 27.05);
    });

    test('zero-price digital row still imports with price null', () {
      final csv = '$retailHeader\n'
          '${retailRow(unitPrice: 'Not Available', totalOwed: '0')}\n';
      final items = service.parseFromCsv(csv);
      expect(items.length, 1);
      expect(items.first.price, isNull);
    });

    test('quantity above one lands in notes as "Qty: N"', () {
      final csv = '$retailHeader\n${retailRow(quantity: '3')}\n';
      final items = service.parseFromCsv(csv);
      expect(items.first.notes, 'Qty: 3');
    });

    test('quantity of one leaves notes empty', () {
      final csv = '$retailHeader\n${retailRow(quantity: '1')}\n';
      final items = service.parseFromCsv(csv);
      expect(items.first.notes, isNull);
    });

    test('header matching is case-insensitive and order-independent', () {
      const csv =
          '"product name","unit price","asin","order date","quantity"\n'
          '"Desk Lamp","39.00","B0LAMP","2023-11-12T21:53:11Z","1"\n';
      final items = service.parseFromCsv(csv);
      expect(items.length, 1);
      expect(items.first.name, 'Desk Lamp');
      expect(items.first.price, 39.00);
      expect(items.first.asin, 'B0LAMP');
    });

    test('skips malformed and summary rows without dying', () {
      final csv = '$retailHeader\n'
          '${retailRow()}\n'
          '"just","a","short","row"\n'
          '${retailRow(productName: '', asin: '')}\n'
          '${retailRow(productName: 'Notebook A5', unitPrice: '7.99')}\n';
      final items = service.parseFromCsv(csv);
      expect(items.length, 2);
      expect(items[0].name, 'Coffee Beans 1kg');
      expect(items[1].name, 'Notebook A5');
    });

    test('legacy format keeps parsing exactly as before (regression)', () {
      const csv =
          '"Order Date","Order ID","Title","Category","ASIN/ISBN","Quantity","Item Total"\n'
          '"2024-01-15","123-456","Coffee Beans 1kg","Grocery","B00ABC","1","\$24.99"\n';
      final items = service.parseFromCsv(csv);
      expect(items.length, 1);
      expect(items.first.name, 'Coffee Beans 1kg');
      expect(items.first.price, 24.99);
      expect(items.first.categoryHint, 'Grocery');
    });
  });

  // --- Header-driven auto-detection (filename plays no part) ---

  group('parse (auto-detect)', () {
    test('routes Retail.OrderHistory content to the CSV parser', () {
      final items = service.parse('$retailHeader\n${retailRow()}\n');
      expect(items.length, 1);
      expect(items.first.name, 'Coffee Beans 1kg');
      expect(items.first.source, ImportSource.amazonCsv);
    });

    test('routes legacy report content to the CSV parser', () {
      const csv =
          '"Order Date","Order ID","Title","Category","ASIN/ISBN","Quantity","Item Total"\n'
          '"2024-01-15","123","Widget","","B00XYZ","1","\$9.99"\n';
      final items = service.parse(csv);
      expect(items.length, 1);
      expect(items.first.source, ImportSource.amazonCsv);
    });

    test('routes non-CSV content to the text parser', () {
      final items = service.parse('Item: Widget\nPrice: \$5.00\n');
      expect(items.length, 1);
      expect(items.first.source, ImportSource.amazonText);
    });
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

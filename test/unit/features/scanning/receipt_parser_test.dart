import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/scanning/domain/receipt_parser.dart';

void main() {
  const parser = ReceiptParser();

  group('ReceiptParser.parse', () {
    test('extracts store name from first non-empty line', () {
      final result = parser.parse('Walmart\n01/15/2024\nTotal 12.34');
      expect(result.storeName, 'Walmart');
    });

    test('returns null store name for empty text', () {
      final result = parser.parse('');
      expect(result.storeName, isNull);
    });

    test('extracts MM/DD/YYYY date', () {
      final result = parser.parse('Store\n01/15/2024\nItem  5.00');
      expect(result.date, '01/15/2024');
    });

    test('extracts YYYY-MM-DD date', () {
      final result = parser.parse('Store\n2024-01-15\nItem  5.00');
      expect(result.date, '2024-01-15');
    });

    test('returns null date when none found', () {
      final result = parser.parse('Store\nItem  5.00');
      expect(result.date, isNull);
    });

    test('extracts total from "total" keyword line', () {
      final result = parser.parse(
        'Store\n01/15/2024\nApple  2.50\nBanana  1.00\nTotal  3.50',
      );
      expect(result.total, isNotNull);
      expect(result.total, contains('3.50'));
    });

    test('falls back to last price when no total keyword', () {
      final result = parser.parse('Store\n01/15/2024\nItem A  2.50\n5.00');
      expect(result.total, isNotNull);
    });

    test('extracts line items with prices', () {
      final result = parser.parse(
        'Target\n03/01/2024\nMilk  3.99\nBread  2.49\nTotal  6.48',
      );
      expect(result.lineItems, hasLength(2));
      expect(result.lineItems.first.name, 'Milk');
      expect(result.lineItems.first.price, '3.99');
      expect(result.lineItems[1].name, 'Bread');
    });

    test('skips total/subtotal/tax lines as line items', () {
      final result = parser.parse('Store\nItem  5.00\nTax  0.40\nTotal  5.40');
      // Only "Item" should be a line item
      expect(result.lineItems, hasLength(1));
      expect(result.lineItems.first.name, 'Item');
    });

    test('skips subtotal line', () {
      final result = parser.parse(
        'Store\nApple  1.00\nSubtotal  1.00\nTotal  1.00',
      );
      expect(result.lineItems, hasLength(1));
      expect(result.lineItems.first.name, 'Apple');
    });

    test('handles empty line items gracefully', () {
      final result = parser.parse('Store\n01/01/2024\nTotal  10.00');
      expect(result.lineItems, isEmpty);
    });

    test('handles comma decimal separator in prices', () {
      final result = parser.parse('Store\nItem  3,99\nTotal  3,99');
      // The total regex should match comma-formatted prices
      expect(result.total, isNotNull);
    });

    test('returns complete result with all fields', () {
      const receipt = '''
Best Buy
Receipt 04/10/2024
Samsung TV  899.99
HDMI Cable  19.99
Subtotal  919.98
Tax  73.60
Total  993.58
''';
      final result = parser.parse(receipt);
      expect(result.storeName, 'Best Buy');
      expect(result.date, '04/10/2024');
      expect(result.total, isNotNull);
      expect(result.lineItems.length, greaterThanOrEqualTo(2));
    });
  });
}

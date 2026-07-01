import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/import/receipt_parser.dart';

/// The ONE deterministic receipt parser — consolidation of the three
/// near-duplicates that used to live in services/import (live but crude),
/// features/scanning (orphaned demo), and features/store_integration
/// (dead code). Tests ported from all three plus realistic OCR fixtures.
void main() {
  const parser = ReceiptParser();

  // ── Ported: store name (scanning + store_integration) ──────────────────

  group('store name', () {
    test('extracts store name from first non-empty line', () {
      final result = parser.parse('Walmart\n01/15/2024\nTotal 12.34');
      expect(result.storeName, 'Walmart');
    });

    test('returns null store name for empty text', () {
      final result = parser.parse('');
      expect(result.storeName, isNull);
    });

    test('skips price/date/total lines when finding the store name', () {
      // store_integration behavior: the first of the top lines that is not
      // a price, date, or total line is the store name.
      final result = parser.parse('01/15/2024\nWalmart\nTotal 12.34');
      expect(result.storeName, 'Walmart');
    });
  });

  // ── Ported: date (scanning + store_integration, typed) ─────────────────

  group('purchase date', () {
    test('extracts MM/DD/YYYY date as a DateTime', () {
      final result = parser.parse('Store\n01/15/2024\nItem  5.00');
      expect(result.purchaseDate, DateTime(2024, 1, 15));
    });

    test('extracts YYYY-MM-DD date as a DateTime', () {
      final result = parser.parse('Store\n2024-01-15\nItem  5.00');
      expect(result.purchaseDate, DateTime(2024, 1, 15));
    });

    test('extracts MM/DD/YY date as a 20xx DateTime', () {
      final result = parser.parse('Store\n01/15/24\nItem  5.00');
      expect(result.purchaseDate, DateTime(2024, 1, 15));
    });

    test('returns null date when none found', () {
      final result = parser.parse('Store\nItem  5.00');
      expect(result.purchaseDate, isNull);
    });

    test('ignores impossible date values instead of crashing', () {
      // 13/45/2024 is not a date; parser must keep searching / yield null.
      final result = parser.parse('Store\n13/45/2024\nItem  5.00');
      expect(result.purchaseDate, isNull);
    });
  });

  // ── Ported: total (scanning's negative-lookbehind + typed amount) ──────

  group('total', () {
    test('extracts total from "total" keyword line as a double', () {
      final result = parser.parse(
        'Store\n01/15/2024\nApple  2.50\nBanana  1.00\nTotal  3.50',
      );
      expect(result.totalAmount, 3.50);
    });

    test('detects Total, not Subtotal (substring "total" must not match)',
        () {
      final r =
          parser.parse('Store\nSubtotal  45.00\nTax  5.00\nTotal  50.00');
      expect(r.totalAmount, 50.00,
          reason: 'must read the Total line, not the Subtotal line');
    });

    test('reads the Amount Due keyword too', () {
      final r = parser.parse('Store\nItem  5.00\nAmount Due  5.40');
      expect(r.totalAmount, 5.40);
    });

    test('falls back to last price when no total keyword', () {
      final result = parser.parse('Store\n01/15/2024\nItem A  2.50\n5.00');
      expect(result.totalAmount, 5.00);
    });

    test('handles comma decimal separator in the total', () {
      final result = parser.parse('Store\nItem  3,99\nTotal  3,99');
      expect(result.totalAmount, 3.99);
    });

    test('handles thousands separators in the total', () {
      final result = parser.parse('Store\nTV  1,299.99\nTotal  1,299.99');
      expect(result.totalAmount, 1299.99);
    });

    test('returns null total when no price exists anywhere', () {
      final result = parser.parse('Store\nThank you for shopping');
      expect(result.totalAmount, isNull);
    });
  });

  // ── Ported: line items (all three) ─────────────────────────────────────

  group('line items', () {
    test('extracts line items with typed prices', () {
      final result = parser.parse(
        'Target\n03/01/2024\nMilk  3.99\nBread  2.49\nTotal  6.48',
      );
      expect(result.lineItems, hasLength(2));
      expect(result.lineItems.first.name, 'Milk');
      expect(result.lineItems.first.price, 3.99);
      expect(result.lineItems[1].name, 'Bread');
      expect(result.lineItems[1].price, 2.49);
    });

    test('skips total/subtotal/tax lines as line items', () {
      final result =
          parser.parse('Store\nItem  5.00\nTax  0.40\nTotal  5.40');
      expect(result.lineItems, hasLength(1));
      expect(result.lineItems.first.name, 'Item');
    });

    test('skips tip/change/cash/credit/debit/balance lines', () {
      final result = parser.parse('Store\n'
          'Coffee  5.00\n'
          'Tip  1.00\n'
          'Change  0.60\n'
          'Cash  10.00\n'
          'Credit  0.00\n'
          'Debit  0.00\n'
          'Balance  0.00\n'
          'Amount Due  6.00');
      expect(result.lineItems, hasLength(1));
      expect(result.lineItems.first.name, 'Coffee');
    });

    test('handles receipts with no line items gracefully', () {
      final result = parser.parse('Store\n01/01/2024\nTotal  10.00');
      expect(result.lineItems, isEmpty);
    });

    test('keeps items whose names merely CONTAIN a skip word', () {
      // Regression: the consolidated parser matched skip words anywhere
      // in the line, silently dropping real items ("TIP" in SIRLOIN TIP,
      // "VISA" in IMPROVISATION). Skip lines are tender/total lines that
      // START with the keyword.
      final result = parser.parse('Store\n'
          'SIRLOIN TIP ROAST  12.99\n'
          'IMPROVISATION BOOK  8.50\n'
          'Total  21.49');
      expect(
        result.lineItems.map((i) => i.name),
        ['SIRLOIN TIP ROAST', 'IMPROVISATION BOOK'],
      );
    });

    test('keeps items that merely START with a skip-word prefix', () {
      // "TAXI" starts with "tax", "CASHEW" with "cash" — a word boundary
      // must end the keyword for the line to be skipped.
      final result = parser.parse('Store\n'
          'TAXI FARE  20.00\n'
          'CASHEW NUTS  5.99\n'
          'Total  25.99');
      expect(
        result.lineItems.map((i) => i.name),
        ['TAXI FARE', 'CASHEW NUTS'],
      );
    });

    test('still skips card-brand tender lines', () {
      final result = parser.parse('Store\n'
          'Coffee  5.00\n'
          'VISA  5.00\n'
          'Mastercard  0.00\n'
          'Total  5.00');
      expect(result.lineItems, hasLength(1));
      expect(result.lineItems.first.name, 'Coffee');
    });

    test('ignores price-only noise lines (no letters in the name)', () {
      final result = parser.parse('Store\n2 @ 1.25\nCoke 12pk  2.50');
      expect(result.lineItems, hasLength(1));
      expect(result.lineItems.first.name, 'Coke 12pk');
    });

    test('accepts a \$ prefix on prices', () {
      final result = parser.parse('Store\nCoffee Beans  \$12.99');
      expect(result.lineItems.single.price, 12.99);
    });
  });

  // ── rawText retained (store_integration behavior) ──────────────────────

  test('retains the raw OCR text verbatim', () {
    const text = 'Store\nItem  5.00\nTotal  5.00';
    expect(parser.parse(text).rawText, text);
  });

  // ── Realistic OCR fixtures ─────────────────────────────────────────────

  group('realistic OCR fixtures', () {
    test('grocery receipt', () {
      const text = '''
KROGER
123 MAIN ST
07/02/2026
BANANAS  0.68
MILK 2% GAL  3.49
COKE 12PK  2.50
SUBTOTAL  6.67
TAX  0.42
TOTAL  7.09
''';
      final r = parser.parse(text);
      expect(r.storeName, 'KROGER');
      expect(r.purchaseDate, DateTime(2026, 7, 2));
      expect(r.totalAmount, 7.09);
      expect(r.lineItems.map((i) => i.name),
          containsAll(['BANANAS', 'MILK 2% GAL', 'COKE 12PK']));
      expect(
        r.lineItems.firstWhere((i) => i.name == 'MILK 2% GAL').price,
        3.49,
      );
    });

    test('electronics receipt with printed model numbers', () {
      const text = '''
BEST BUY
STORE 447
04/10/2024
SAMSUNG UN55TU7000 55" TV  499.99
SONY WH-1000XM4 HEADPHONES  278.00
HDMI CABLE 6FT  19.99
SUBTOTAL  797.98
TAX  63.84
TOTAL  861.82
VISA  861.82
''';
      final r = parser.parse(text);
      expect(r.storeName, 'BEST BUY');
      expect(r.purchaseDate, DateTime(2024, 4, 10));
      expect(r.totalAmount, 861.82);
      // Model numbers survive verbatim in the deterministic name — the
      // LLM stage is the one that splits brand/model out.
      expect(
        r.lineItems.map((i) => i.name),
        contains('SAMSUNG UN55TU7000 55" TV'),
      );
      expect(r.lineItems.map((i) => i.name), isNot(contains('VISA')));
    });

    test('faded/partial receipt degrades gracefully', () {
      // OCR of a faded thermal receipt: garbled store line, no usable
      // date, one legible item, no total keyword.
      const text = '''
W..M..T
xx/xx/xxxx
DISH SOAP  3.49
.....  .....
9.13
''';
      final r = parser.parse(text);
      expect(r.storeName, 'W..M..T');
      expect(r.purchaseDate, isNull);
      expect(r.lineItems.single.name, 'DISH SOAP');
      expect(r.totalAmount, 9.13,
          reason: 'falls back to the last price-looking token');
    });

    test('multi-quantity receipt keeps the priced lines', () {
      const text = '''
COSTCO WHOLESALE
06/30/2026
KS WATER 40PK  3.99
2 @ 3.99
KS PAPER TOWELS  18.99
TOTAL  26.97
''';
      final r = parser.parse(text);
      expect(r.storeName, 'COSTCO WHOLESALE');
      expect(r.totalAmount, 26.97);
      expect(r.lineItems.map((i) => i.name),
          containsAll(['KS WATER 40PK', 'KS PAPER TOWELS']));
      expect(r.lineItems.map((i) => i.name), isNot(contains('2 @')),
          reason: 'quantity-only continuation lines are OCR noise here');
    });
  });
}

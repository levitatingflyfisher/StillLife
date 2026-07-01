import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/extensions/currency_extensions.dart';
import 'package:still_life/core/utils/money.dart';
import 'package:still_life/core/utils/money_input.dart';

/// The cents law: money is STORED as integer cents (exact arithmetic,
/// no float drift) and travels every wire — backup JSON, CSV, sync — as
/// decimal dollars. These helpers are the only crossing points.
void main() {
  group('centsFromDollars', () {
    test('scales whole dollars exactly', () {
      expect(centsFromDollars(10.50), 1050);
      expect(centsFromDollars(0.01), 1);
      expect(centsFromDollars(0), 0);
      expect(centsFromDollars(250000), 25000000);
    });

    test('rounds half away from zero with decimal semantics', () {
      // 1.005 is stored as 1.00499999999999989 in binary; the decimal
      // reading must still round UP, matching roundToCents.
      expect(centsFromDollars(1.005), 101);
      expect(centsFromDollars(2.675), 268);
      expect(centsFromDollars(-1.005), -101);
    });

    test('rounds sub-cent junk from unrounded legacy writes', () {
      expect(centsFromDollars(123.456), 12346);
      expect(centsFromDollars(0.1 + 0.2), 30);
    });

    test('null variant passes null through', () {
      expect(centsFromDollarsOrNull(null), isNull);
      expect(centsFromDollarsOrNull(16.48), 1648);
    });
  });

  group('dollarsFromCents', () {
    test('is the exact inverse for whole cents', () {
      expect(dollarsFromCents(1050), 10.50);
      expect(dollarsFromCents(1), 0.01);
      expect(dollarsFromCents(-101), -1.01);
      expect(dollarsFromCentsOrNull(null), isNull);
      expect(dollarsFromCentsOrNull(1648), 16.48);
    });

    test('roundtrips through the wire representation', () {
      for (final cents in [0, 1, 99, 1050, 12346, 25000000, -27550]) {
        expect(centsFromDollars(dollarsFromCents(cents)), cents);
      }
    });
  });

  group('parseMoneyInputCents', () {
    test('parses user text straight to cents', () {
      expect(parseMoneyInputCents('12.50'), 1250);
      expect(parseMoneyInputCents(r'$1,234.01'), 123401);
      expect(parseMoneyInputCents('87.5'), 8750);
    });

    test('propagates the ambiguous / invalid cases as null', () {
      expect(parseMoneyInputCents('1,234'), isNull);
      expect(parseMoneyInputCents('not money'), isNull);
      expect(parseMoneyInputCents(''), isNull);
    });
  });

  group('cents formatting extensions', () {
    test('formats cents as currency', () {
      expect(1050.centsToCurrency(), r'$10.50');
      expect(1.centsToCurrency(), r'$0.01');
      expect(25000000.centsToCurrency(), r'$250,000.00');
    });

    test('nullable variant renders empty for null', () {
      const int? none = null;
      expect(none.centsToCurrencyOrEmpty(), '');
      expect((1648 as int?).centsToCurrencyOrEmpty(), r'$16.48');
    });
  });
}

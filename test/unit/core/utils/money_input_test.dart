import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/utils/money_input.dart';

void main() {
  group('parseMoneyInput', () {
    test('plain dot-decimal input parses as before', () {
      expect(parseMoneyInput('12.50'), 12.50);
      expect(parseMoneyInput('12'), 12.0);
      expect(parseMoneyInput('0'), 0.0);
      expect(parseMoneyInput('.50'), 0.50);
    });

    test('comma with no dot is a decimal separator', () {
      expect(parseMoneyInput('12,50'), 12.50);
      expect(parseMoneyInput('0,99'), 0.99);
      expect(parseMoneyInput('1234,56'), 1234.56);
    });

    test('both separators: the last one is the decimal separator', () {
      expect(parseMoneyInput('1.234,56'), 1234.56);
      expect(parseMoneyInput('1,234.56'), 1234.56);
      expect(parseMoneyInput('1.234.567,89'), 1234567.89);
      expect(parseMoneyInput('1,234,567.89'), 1234567.89);
    });

    test('repeated same-side separators are thousands grouping', () {
      expect(parseMoneyInput('1,234,567'), 1234567.0);
      expect(parseMoneyInput('1.234.567'), 1234567.0);
    });

    test('currency symbols and spaces are trimmed', () {
      expect(parseMoneyInput(r'$12.50'), 12.50);
      expect(parseMoneyInput('€ 12,50'), 12.50);
      expect(parseMoneyInput(' 12.50 '), 12.50);
      expect(parseMoneyInput('£1,234.56'), 1234.56);
      // Non-breaking / narrow no-break spaces show up as locale grouping.
      expect(parseMoneyInput('1 234,56'), 1234.56);
      expect(parseMoneyInput('1 234,56'), 1234.56);
    });

    test('a trailing decimal separator is tolerated (mid-typing save)', () {
      expect(parseMoneyInput('12.'), 12.0);
      expect(parseMoneyInput('12,'), 12.0);
    });

    test(
        'AMBIGUOUS single-separator-then-3-digits returns null instead of a '
        '1000x-corrupting guess', () {
      // A US user typing "1,234" means one thousand; the old code read it
      // as 1.234 and saved $1.23. The reading is genuinely ambiguous, so
      // the parser must refuse rather than silently pick a side.
      expect(parseMoneyInput('1,234'), isNull);
      expect(parseMoneyInput('1.234'), isNull);
      expect(parseMoneyInput('12,345'), isNull);
      expect(parseMoneyInput('12.345'), isNull);
      expect(parseMoneyInput('123,456'), isNull);
      expect(parseMoneyInput(r'$1,234'), isNull,
          reason: 'decoration stripping must not hide the ambiguity');
    });

    test('unambiguous neighbours of the ambiguous forms keep working', () {
      expect(parseMoneyInput('12,50'), 12.50);
      expect(parseMoneyInput('1,234.56'), 1234.56);
      expect(parseMoneyInput('1.234,56'), 1234.56);
      expect(parseMoneyInput('1,234,567'), 1234567.0);
      // A 4+ digit integer part cannot be thousands grouping, so a 3-digit
      // fraction is unambiguously decimal.
      expect(parseMoneyInput('1234,567'), 1234.567);
      expect(parseMoneyInput('1234.567'), 1234.567);
      // An empty integer part cannot be grouping either.
      expect(parseMoneyInput('.234'), 0.234);
      expect(parseMoneyInput(',234'), 0.234);
    });

    test('unparseable input returns null instead of a guess', () {
      expect(parseMoneyInput(''), isNull);
      expect(parseMoneyInput('   '), isNull);
      expect(parseMoneyInput('abc'), isNull);
      expect(parseMoneyInput('12,5x'), isNull);
      expect(parseMoneyInput('12..5'), isNull);
      expect(parseMoneyInput('1,2,3'), isNull);
      expect(parseMoneyInput('1.23.4,5'), isNull);
      expect(parseMoneyInput(','), isNull);
      expect(parseMoneyInput('.'), isNull);
    });
  });

  group('validateMoneyInput', () {
    test('empty is valid (no price is a legal state)', () {
      expect(validateMoneyInput(null), isNull);
      expect(validateMoneyInput(''), isNull);
      expect(validateMoneyInput('   '), isNull);
    });

    test('parseable input is valid', () {
      expect(validateMoneyInput('12.50'), isNull);
      expect(validateMoneyInput('12,50'), isNull);
    });

    test('garbage surfaces an error message', () {
      expect(validateMoneyInput('abc'), 'Enter a valid amount');
      expect(validateMoneyInput('12,5x'), 'Enter a valid amount');
    });

    test('ambiguous input surfaces an ACTIONABLE message, not the generic one',
        () {
      expect(validateMoneyInput('1,234'),
          'Ambiguous amount — use 1234 or 1,234.00');
      expect(validateMoneyInput('1.234'),
          'Ambiguous amount — use 1234 or 1,234.00');
      expect(validateMoneyInput(r'$12,345'),
          'Ambiguous amount — use 1234 or 1,234.00');
    });
  });
}

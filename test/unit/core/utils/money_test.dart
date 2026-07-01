import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/utils/money.dart';

/// The rounding law: money rounds to whole cents at the write boundary,
/// with decimal half-up semantics ("10.005" is a cent-and-a-half boundary
/// case, and the user-visible answer is 10.01 — not whatever the nearest
/// binary double happens to truncate to).
void main() {
  group('roundToCents', () {
    test('half-cent rounds up despite binary representation', () {
      // 10.005 is stored as 10.00499999999999989... — naive
      // (v*100).round()/100 gives 10.00. The law says 10.01.
      expect(roundToCents(10.005), 10.01);
      expect(roundToCents(2.675), 2.68);
      expect(roundToCents(1.005), 1.01);
    });

    test('floating-point artifacts collapse to clean cents', () {
      expect(roundToCents(0.1 + 0.2), 0.30);
      expect(roundToCents(1.1 + 2.2), 3.30);
    });

    test('ordinary values round half away from zero', () {
      expect(roundToCents(123.456789), 123.46);
      expect(roundToCents(10.004), 10.00);
      expect(roundToCents(10.006), 10.01);
      expect(roundToCents(-10.005), -10.01);
      expect(roundToCents(-10.004), -10.00);
    });

    test('already-clean values pass through', () {
      expect(roundToCents(0), 0.0);
      expect(roundToCents(12.50), 12.50);
      expect(roundToCents(799.99), 799.99);
      expect(roundToCents(1234567.89), 1234567.89);
    });
  });

  group('roundToCentsOrNull', () {
    test('null (no price) stays null', () {
      expect(roundToCentsOrNull(null), isNull);
    });

    test('non-null delegates to the law', () {
      expect(roundToCentsOrNull(10.005), 10.01);
    });
  });
}

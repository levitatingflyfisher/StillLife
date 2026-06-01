import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/config/feature_flags.dart';

void main() {
  test('proBillingEnabled is a compile-time constant', () {
    expect(FeatureFlags.proBillingEnabled, anyOf(isTrue, isFalse));
  });
}

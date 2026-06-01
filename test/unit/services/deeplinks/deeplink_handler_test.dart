import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/billing/domain/billing_service.dart';
import 'package:still_life/services/deeplinks/deeplink_handler.dart';

class _FakeBilling extends Mock implements BillingService {}

void main() {
  test(
    'parses still-life://activate?session_id=cs_x and calls activate',
    () async {
      final b = _FakeBilling();
      when(
        () => b.activate('cs_x'),
      ).thenAnswer((_) async => const Success(null));
      final h = DeepLinkHandler(billing: b);
      final handled = await h.handle(
        Uri.parse('still-life://activate?session_id=cs_x'),
      );
      expect(handled, isTrue);
      verify(() => b.activate('cs_x')).called(1);
    },
  );

  test('ignores unknown hosts', () async {
    final b = _FakeBilling();
    final h = DeepLinkHandler(billing: b);
    final handled = await h.handle(Uri.parse('still-life://unknown?foo=bar'));
    expect(handled, isFalse);
    verifyNever(() => b.activate(any()));
  });

  test('returns false when session_id is missing', () async {
    final b = _FakeBilling();
    final h = DeepLinkHandler(billing: b);
    final handled = await h.handle(Uri.parse('still-life://activate'));
    expect(handled, isFalse);
    verifyNever(() => b.activate(any()));
  });

  test('returns false when activate fails', () async {
    final b = _FakeBilling();
    when(
      () => b.activate(any()),
    ).thenAnswer((_) async => const Err(NetworkFailure('boom')));
    final h = DeepLinkHandler(billing: b);
    final handled = await h.handle(
      Uri.parse('still-life://activate?session_id=cs_y'),
    );
    expect(handled, isFalse);
  });
}

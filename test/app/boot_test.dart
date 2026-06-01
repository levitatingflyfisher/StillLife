import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/app/boot.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  test('returns /dashboard when onboarding is marked complete', () async {
    final s = _MockStorage();
    when(() => s.read(key: any(named: 'key'))).thenAnswer((_) async => 'complete');
    expect(await resolveInitialLocation(s), '/dashboard');
  });

  test('returns /onboarding when the flag is unset', () async {
    final s = _MockStorage();
    when(() => s.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    expect(await resolveInitialLocation(s), '/onboarding');
  });

  // The brick-on-launch regression: a secure-storage / keystore failure must
  // NOT propagate out of boot. It defaults to onboarding so the app still opens.
  test('defaults to /onboarding (never throws) when storage read fails', () async {
    final s = _MockStorage();
    when(() => s.read(key: any(named: 'key'))).thenThrow(Exception('keystore unavailable'));
    expect(await resolveInitialLocation(s), '/onboarding');
  });
}

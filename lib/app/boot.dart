import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure-storage key recording that first-run onboarding has completed.
const kOnboardingKey = 'onboarding_v1';

/// The router's initial location, resolved from the persisted onboarding flag.
///
/// Defaults to onboarding if secure storage can't be read. It never throws, so
/// a keystore/storage failure on launch can't abort `main()` before `runApp`
/// (which used to leave the app stuck on the splash screen).
Future<String> resolveInitialLocation(FlutterSecureStorage storage) async {
  try {
    final value = await storage.read(key: kOnboardingKey);
    return value == 'complete' ? '/dashboard' : '/onboarding';
  } catch (_) {
    return '/onboarding';
  }
}

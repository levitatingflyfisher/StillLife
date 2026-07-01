import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/billing/data/stripe_billing_service_impl.dart';
import '../../features/billing/domain/account.dart';
import '../../features/billing/domain/billing_service.dart';

/// Compile-time-configurable base URL for the hosted-LLM proxy.
///
/// Defaults to EMPTY — the hosted tier is disabled unless an operator
/// explicitly opts in via `--dart-define=HOSTED_BASE_URL=https://...`.
/// (The old placeholder default pointed at a domain nothing ties to this
/// project; builds would have sent Authorization bearers and photos to
/// whoever registers it. Fail closed instead.)
const String kHostedBaseUrl = String.fromEnvironment(
  'HOSTED_BASE_URL',
  defaultValue: '',
);

/// Stripe Checkout URL (external browser link), set by operators via
/// `--dart-define=CHECKOUT_URL=...`.
///
/// Defaults to EMPTY, exactly like [kHostedBaseUrl] and for the same
/// reason: the old default pointed at a domain nothing ties to this
/// project, and the Upgrade button would have launched whatever whoever
/// registers it serves — presented to the user as a payment page. Fail
/// closed; the UI hides the CTA when unset.
const String kCheckoutUrl = String.fromEnvironment(
  'CHECKOUT_URL',
  defaultValue: '',
);

/// Singleton BillingService for the app. Holds a Dio instance scoped to
/// billing requests (separate from `_mlDioProvider`) so it can be
/// overridden in tests without affecting analysis providers.
final billingServiceProvider = Provider<BillingService>((ref) {
  return StripeBillingServiceImpl(
    dio: Dio(),
    storage: const FlutterSecureStorage(),
    baseUrl: kHostedBaseUrl,
    checkoutUrl: Uri.parse(kCheckoutUrl),
  );
});

/// Async-loaded account state. Returns `null` when the user has no
/// bearer token (i.e. not subscribed). UI layers should branch on this
/// to show UpgradeCta vs. UsageMeter.
final accountProvider = AsyncNotifierProvider<AccountNotifier, Account?>(
  AccountNotifier.new,
);

class AccountNotifier extends AsyncNotifier<Account?> {
  @override
  Future<Account?> build() async {
    final svc = ref.watch(billingServiceProvider);
    if (!await svc.hasBearer()) return null;
    final r = await svc.getAccount();
    return r.when(success: (a) => a, failure: (_) => null);
  }

  /// Force-refresh account state (used after activate, rotate, delete,
  /// and deep-link returns). Calling [build] directly is a Riverpod
  /// anti-pattern — it bypasses dependency tracking and lifecycle hooks.
  /// invalidateSelf() lets the framework rebuild correctly.
  void refresh() {
    ref.invalidateSelf();
  }
}

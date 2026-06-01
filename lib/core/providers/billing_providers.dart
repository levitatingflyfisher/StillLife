import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/billing/data/stripe_billing_service_impl.dart';
import '../../features/billing/domain/account.dart';
import '../../features/billing/domain/billing_service.dart';

/// Compile-time-configurable base URL for the hosted-LLM proxy.
///
/// In debug builds this points at the production host; wranglers/operators
/// override it via `--dart-define=HOSTED_BASE_URL=https://staging...` when
/// testing against staging or local `wrangler dev`.
const String kHostedBaseUrl = String.fromEnvironment(
  'HOSTED_BASE_URL',
  defaultValue: 'https://hosted-llm.stilllife.app',
);

/// Stripe Checkout URL (external browser link). Overridable via
/// `--dart-define=CHECKOUT_URL=...` to target test-mode Stripe.
const String kCheckoutUrl = String.fromEnvironment(
  'CHECKOUT_URL',
  defaultValue: 'https://stilllife.app/pro/checkout',
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

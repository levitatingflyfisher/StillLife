import 'package:still_life/features/billing/domain/billing_service.dart';

/// Handles inbound `still-life://` deep links.
///
/// Currently the only supported host is `activate`, which carries a
/// Stripe Checkout session id as a query parameter. Other hosts are
/// ignored so future additions don't accidentally crash on older builds.
class DeepLinkHandler {
  final BillingService billing;

  DeepLinkHandler({required this.billing});

  /// Returns `true` if the link was recognised and successfully handled,
  /// `false` otherwise. Callers should refresh the account provider when
  /// `true` is returned so the UI reflects the new subscription state.
  Future<bool> handle(Uri uri) async {
    if (uri.host != 'activate') return false;
    final sessionId = uri.queryParameters['session_id'];
    if (sessionId == null || sessionId.isEmpty) return false;
    final r = await billing.activate(sessionId);
    return r.when(success: (_) => true, failure: (_) => false);
  }
}

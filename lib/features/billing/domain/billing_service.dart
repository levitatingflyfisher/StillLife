import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/billing/domain/account.dart';

/// Contract for the Pro-billing backend (Stripe + hosted-LLM proxy).
///
/// The implementation persists a bearer token in secure storage and uses
/// it to call `/v1/account`, `/v1/activate`, `/v1/rotate`, and `/v1/account`
/// (DELETE). All methods return [Result] so call sites can distinguish
/// network/validation failures from success.
abstract class BillingService {
  /// Fetch the current account state. Returns `ValidationFailure` if the
  /// bearer is missing (caller should show UpgradeCta instead).
  Future<Result<Account>> getAccount();

  /// Exchange a Stripe Checkout Session ID for a bearer token. The returned
  /// bearer is persisted to secure storage on success.
  Future<Result<void>> activate(String sessionId);

  /// Rotate the bearer token (invalidates the prior one server-side).
  Future<Result<void>> rotateBearer();

  /// Delete the Pro account (cancels subscription and erases server
  /// record). Clears the local bearer on success.
  Future<Result<void>> deleteAccount();

  /// The Stripe Checkout URL users open in an external browser to upgrade.
  Uri buildCheckoutUrl();

  /// Whether a bearer token is present in secure storage.
  Future<bool> hasBearer();
}

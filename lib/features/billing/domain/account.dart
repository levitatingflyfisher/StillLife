import 'package:equatable/equatable.dart';

/// Subscription status, mirroring the server's `/v1/account` response.
enum SubscriptionStatus { active, pastDue, canceled, none }

/// Snapshot of the user's hosted-LLM account as returned by the server.
///
/// All fields are derived from the authoritative server state; the client
/// never mutates these directly. `usageFraction` is clamped at render time
/// by the UI layer.
class Account extends Equatable {
  final String tier;
  final SubscriptionStatus status;
  final int tokensUsedMonth;
  final int tokensMonthCap;
  final DateTime monthResetAt;

  const Account({
    required this.tier,
    required this.status,
    required this.tokensUsedMonth,
    required this.tokensMonthCap,
    required this.monthResetAt,
  });

  double get usageFraction =>
      tokensMonthCap == 0 ? 0 : tokensUsedMonth / tokensMonthCap;

  bool get isActive => status == SubscriptionStatus.active;

  @override
  List<Object?> get props => [
    tier,
    status,
    tokensUsedMonth,
    tokensMonthCap,
    monthResetAt,
  ];
}

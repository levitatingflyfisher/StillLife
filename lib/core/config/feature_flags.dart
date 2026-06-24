import 'package:flutter/foundation.dart';

/// Compile-time feature flags.
///
/// These are toggled via `--dart-define=FLAG=value` at build time. The
/// `PRO_BILLING_ENABLED` flag gates the Phase 22a Pro & Billing UI. It
/// defaults to `kDebugMode`, so it is visible in debug builds while
/// remaining hidden in release builds until the hosted LLM proxy is
/// production-ready.
class FeatureFlags {
  const FeatureFlags._();

  /// Whether the Pro & Billing surface (Settings tile, /settings/pro route,
  /// deep-link activation flow) is exposed in the UI.
  static const bool proBillingEnabled = bool.fromEnvironment(
    'PRO_BILLING_ENABLED',
    defaultValue: kDebugMode,
  );
}

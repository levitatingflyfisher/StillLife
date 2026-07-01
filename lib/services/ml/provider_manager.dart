import 'package:still_life/services/ml/analysis_provider.dart';

/// Manages the 4-tier hierarchy of analysis providers.
///
/// Providers are checked in priority order. The priority list is
/// user-configurable and defaults to [kDefaultTierPriority]
/// (quality-first, on-device last).
class ProviderManager {
  final Map<AnalysisTier, AnalysisProvider> _providers;
  List<AnalysisTier> _priorityOrder;

  ProviderManager({
    required List<AnalysisProvider> providers,
    List<AnalysisTier>? priorityOrder,
  }) : _providers = {for (final p in providers) p.tier: p},
       _priorityOrder = priorityOrder ?? List.of(kDefaultTierPriority);

  /// The current priority ordering of tiers.
  List<AnalysisTier> get priorityOrder => List.unmodifiable(_priorityOrder);

  /// Updates the priority order for provider selection.
  set priorityOrder(List<AnalysisTier> order) {
    _priorityOrder = List.of(order);
  }

  /// Returns the first available provider that can serve [capability],
  /// according to the priority order.
  ///
  /// Returns `null` if no capable provider is currently available. The
  /// capability check runs before the (potentially network-probing)
  /// availability check.
  Future<AnalysisProvider?> getBestAvailable(
    AnalysisCapability capability,
  ) async {
    for (final tier in _priorityOrder) {
      final provider = _providers[tier];
      if (provider != null &&
          provider.capabilities.contains(capability) &&
          await provider.isAvailable()) {
        return provider;
      }
    }
    return null;
  }

  /// Returns the provider registered for a specific [tier], or `null`
  /// if no provider is registered for that tier.
  AnalysisProvider? getByTier(AnalysisTier tier) => _providers[tier];

  /// Checks availability of all registered providers.
  ///
  /// Returns a map from tier to availability status.
  Future<Map<AnalysisTier, bool>> discoverProviders() async {
    final results = <AnalysisTier, bool>{};

    // Check all providers concurrently.
    final futures = _providers.entries.map((entry) async {
      try {
        final available = await entry.value.isAvailable();
        return MapEntry(entry.key, available);
      } catch (_) {
        return MapEntry(entry.key, false);
      }
    });

    for (final entry in await Future.wait(futures)) {
      results[entry.key] = entry.value;
    }

    return results;
  }

  /// All registered tiers.
  Iterable<AnalysisTier> get registeredTiers => _providers.keys;

  /// Whether a provider is registered for the given [tier].
  bool hasProvider(AnalysisTier tier) => _providers.containsKey(tier);
}

import 'package:still_life/services/ml/analysis_provider.dart';

/// Manages the 4-tier hierarchy of analysis providers.
///
/// Providers are checked in priority order. The priority list is
/// user-configurable and defaults to the natural tier ordering:
/// on-device -> local LLM -> cloud API -> hosted.
class ProviderManager {
  final Map<AnalysisTier, AnalysisProvider> _providers;
  List<AnalysisTier> _priorityOrder;

  ProviderManager({
    required List<AnalysisProvider> providers,
    List<AnalysisTier>? priorityOrder,
  }) : _providers = {for (final p in providers) p.tier: p},
       _priorityOrder =
           priorityOrder ??
           [
             AnalysisTier.onDevice,
             AnalysisTier.localLlm,
             AnalysisTier.cloudApi,
             AnalysisTier.hosted,
           ];

  /// The current priority ordering of tiers.
  List<AnalysisTier> get priorityOrder => List.unmodifiable(_priorityOrder);

  /// Updates the priority order for provider selection.
  set priorityOrder(List<AnalysisTier> order) {
    _priorityOrder = List.of(order);
  }

  /// Returns the first available provider according to the priority order.
  ///
  /// Returns `null` if no provider is currently available.
  Future<AnalysisProvider?> getBestAvailable() async {
    for (final tier in _priorityOrder) {
      final provider = _providers[tier];
      if (provider != null && await provider.isAvailable()) {
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

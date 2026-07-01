import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/provider_manager.dart';

/// A provider whose tier, availability, and capabilities are set per test.
/// Extends (not implements) so the no-override case exercises the interface
/// default that the four full-LLM tiers rely on.
class _FakeProvider extends AnalysisProvider {
  @override
  final AnalysisTier tier;
  final bool _available;
  final Set<AnalysisCapability>? _capabilities;

  _FakeProvider(
    this.tier, {
    bool available = true,
    Set<AnalysisCapability>? capabilities,
  }) : _available = available,
       _capabilities = capabilities;

  @override
  String get name => 'fake-${tier.name}';

  @override
  Set<AnalysisCapability> get capabilities =>
      _capabilities ?? super.capabilities;

  @override
  Future<bool> isAvailable() async => _available;

  @override
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  }) => throw UnimplementedError();

  @override
  Future<List<AnalysisResult>> analyzeImageMulti(
    Uint8List imageBytes, {
    AnalysisContext? context,
  }) => throw UnimplementedError();

  @override
  Future<AnalysisResult> analyzeText(
    String prompt, {
    AnalysisContext? context,
  }) => throw UnimplementedError();

  @override
  Future<String> completeText(String prompt, {int maxTokens = 1000}) =>
      throw UnimplementedError();
}

void main() {
  group('ProviderManager capability-aware selection', () {
    test(
      'getBestAvailable(text) skips an available vision-only tier and '
      'returns the next tier that can handle text',
      () async {
        final visionOnly = _FakeProvider(
          AnalysisTier.onDevice,
          capabilities: const {
            AnalysisCapability.image,
            AnalysisCapability.imageMulti,
          },
        );
        final fullLlm = _FakeProvider(AnalysisTier.localLlm);
        final manager = ProviderManager(providers: [visionOnly, fullLlm]);

        final chosen = await manager.getBestAvailable(AnalysisCapability.text);

        expect(
          chosen?.tier,
          AnalysisTier.localLlm,
          reason:
              'a vision-only on-device tier must never be handed a '
              'text call (receipt structuring, voice intake) — it would '
              'throw instead of analyzing',
        );
      },
    );

    test(
      'getBestAvailable(image) still returns the vision-only tier when it '
      'is first in priority order',
      () async {
        final visionOnly = _FakeProvider(
          AnalysisTier.onDevice,
          capabilities: const {AnalysisCapability.image},
        );
        final fullLlm = _FakeProvider(AnalysisTier.localLlm);
        final manager = ProviderManager(
          providers: [visionOnly, fullLlm],
          // Explicit: the default priority puts onDevice last; this test
          // is about capability routing when it is deliberately first.
          priorityOrder: const [AnalysisTier.onDevice, AnalysisTier.localLlm],
        );

        final chosen = await manager.getBestAvailable(AnalysisCapability.image);

        expect(chosen?.tier, AnalysisTier.onDevice);
      },
    );

    test(
      'getBestAvailable(imageMulti) returns null when the only available '
      'provider lacks the capability',
      () async {
        final singleImageOnly = _FakeProvider(
          AnalysisTier.onDevice,
          capabilities: const {AnalysisCapability.image},
        );
        final offline = _FakeProvider(AnalysisTier.cloudApi, available: false);
        final manager = ProviderManager(
          providers: [singleImageOnly, offline],
        );

        final chosen = await manager.getBestAvailable(
          AnalysisCapability.imageMulti,
        );

        expect(
          chosen,
          isNull,
          reason:
              'an honest "no tier can do this" beats routing a shelf '
              'photo to a provider that will throw',
        );
      },
    );

    test('capabilities defaults to every capability, so the four full-LLM '
        'tiers need no override', () {
      final fake = _FakeProvider(AnalysisTier.hosted);

      expect(fake.capabilities, AnalysisCapability.values.toSet());
    });
  });
}

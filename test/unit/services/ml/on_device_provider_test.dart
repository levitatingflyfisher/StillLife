import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/on_device/on_device_engine.dart';
import 'package:still_life/services/ml/on_device_provider.dart';

class _FakeEngine implements OnDeviceEngine {
  @override
  final String id;
  final bool _available;
  final String _resultName;
  String? lastExistingLabel;

  _FakeEngine(this.id, {required bool available, String resultName = 'Item'})
    : _available = available,
      _resultName = resultName;

  @override
  String get displayName => id;

  @override
  Future<bool> isAvailable() async => _available;

  @override
  Future<AnalysisResult> analyzeImage(
    Uint8List imageBytes, {
    String? existingLabel,
  }) async {
    lastExistingLabel = existingLabel;
    return AnalysisResult(
      itemName: _resultName,
      description: 'from $id',
      category: 'Other',
      confidence: 0.5,
    );
  }
}

void main() {
  group('OnDeviceProvider with no engines (the shipped default today)', () {
    test('isAvailable is false — nothing fabricated', () async {
      final provider = OnDeviceProvider();
      expect(await provider.isAvailable(), isFalse);
    });

    test('analyzeImage throws StateError instead of fabricating data', () {
      final provider = OnDeviceProvider();
      expect(
        () => provider.analyzeImage(imageBytes: Uint8List(4)),
        throwsStateError,
      );
    });
  });

  group('OnDeviceProvider capabilities', () {
    test('declares image ONLY — the cascade must never route it text or '
        'multi-item calls', () {
      final provider = OnDeviceProvider();
      expect(provider.capabilities, {AnalysisCapability.image});
    });

    test('analyzeText always throws — no on-device text model', () {
      final provider = OnDeviceProvider(
        engines: [_FakeEngine('labeler', available: true)],
      );
      expect(() => provider.analyzeText('a prompt'), throwsStateError);
      expect(() => provider.completeText('a prompt'), throwsStateError);
    });

    test('analyzeImageMulti always throws — never fabricates a shelf', () {
      final provider = OnDeviceProvider(
        engines: [_FakeEngine('labeler', available: true)],
      );
      expect(
        () => provider.analyzeImageMulti(Uint8List(4)),
        throwsStateError,
      );
    });
  });

  group('OnDeviceProvider engine cascade', () {
    test('isAvailable is true when ANY engine is available', () async {
      final provider = OnDeviceProvider(
        engines: [
          _FakeEngine('nano', available: false),
          _FakeEngine('labeler', available: true),
        ],
      );
      expect(await provider.isAvailable(), isTrue);
    });

    test('analyzeImage uses the FIRST available engine in list order '
        '(quality order: nano > smolvlm > labeler)', () async {
      final provider = OnDeviceProvider(
        engines: [
          _FakeEngine('nano', available: false, resultName: 'from-nano'),
          _FakeEngine('smolvlm', available: true, resultName: 'from-vlm'),
          _FakeEngine('labeler', available: true, resultName: 'from-labeler'),
        ],
      );

      final result = await provider.analyzeImage(imageBytes: Uint8List(4));

      expect(result.itemName, 'from-vlm');
    });

    test('existingLabel is forwarded to the chosen engine', () async {
      final engine = _FakeEngine('labeler', available: true);
      final provider = OnDeviceProvider(engines: [engine]);

      await provider.analyzeImage(
        imageBytes: Uint8List(4),
        existingLabel: 'garage shelf',
      );

      expect(engine.lastExistingLabel, 'garage shelf');
    });

    test('analyzeImage throws StateError when engines exist but none is '
        'available — never picks an unavailable engine', () {
      final provider = OnDeviceProvider(
        engines: [_FakeEngine('nano', available: false)],
      );
      expect(
        () => provider.analyzeImage(imageBytes: Uint8List(4)),
        throwsStateError,
      );
    });
  });
}

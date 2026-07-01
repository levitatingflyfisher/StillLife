import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/on_device/nano_engine.dart';
import 'package:still_life/services/ml/single_item_parser.dart';

class _FakeNanoGateway implements NanoGateway {
  final NanoStatus status;
  final String reply;
  String? lastPrompt;
  Uint8List? lastImageBytes;

  _FakeNanoGateway({this.status = NanoStatus.available, this.reply = '{}'});

  @override
  Future<NanoStatus> checkStatus() async => status;

  @override
  Future<void> requestSetup() async {}

  @override
  Future<String> promptWithImage({
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    lastPrompt = prompt;
    lastImageBytes = imageBytes;
    return reply;
  }
}

void main() {
  group('NanoEngine availability', () {
    test('available ONLY when AICore reports the feature ready — '
        'downloadable is NOT available (setup is a user action)', () async {
      for (final (status, expected) in [
        (NanoStatus.available, true),
        (NanoStatus.downloadable, false),
        (NanoStatus.downloading, false),
        (NanoStatus.unsupported, false),
      ]) {
        final engine = NanoEngine(gateway: _FakeNanoGateway(status: status));
        expect(
          await engine.isAvailable(),
          expected,
          reason: 'status $status',
        );
      }
    });

    test('identifies as nano', () {
      final engine = NanoEngine(gateway: _FakeNanoGateway());
      expect(engine.id, 'nano');
    });
  });

  group('NanoEngine analyzeImage', () {
    final photo = Uint8List.fromList([1, 2, 3]);

    test('sends the shared single-item prompt and parses the JSON reply at '
        'confidence 0.75 (flagship on-device, below cloud 0.85)', () async {
      final gateway = _FakeNanoGateway(
        reply:
            '{"name": "Stand Mixer", "brand": "KitchenAid", '
            '"description": "5qt tilt-head", "category": "Appliance", '
            '"estimatedRetailPrice": 379.99}',
      );
      final engine = NanoEngine(gateway: gateway);

      final result = await engine.analyzeImage(photo);

      expect(gateway.lastPrompt, kSingleItemAnalysisPrompt);
      expect(gateway.lastImageBytes, photo);
      expect(result.itemName, 'Stand Mixer');
      expect(result.brand, 'KitchenAid');
      expect(result.confidence, 0.75);
    });

    test('prefixes existingLabel exactly like the other tiers', () async {
      final gateway = _FakeNanoGateway();
      final engine = NanoEngine(gateway: gateway);

      await engine.analyzeImage(photo, existingLabel: 'kitchen counter');

      expect(
        gateway.lastPrompt,
        'This item has been labeled "kitchen counter". '
        '$kSingleItemAnalysisPrompt',
      );
    });

    test('a prose reply degrades via the shared parser, never crashes',
        () async {
      final engine = NanoEngine(
        gateway: _FakeNanoGateway(reply: 'This appears to be a mixer.'),
      );
      final result = await engine.analyzeImage(photo);
      expect(result.itemName, 'Unknown Item');
      expect(result.confidence, 0.4);
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/model_store_io.dart';
import 'package:still_life/services/ml/on_device/smolvlm_engine.dart';
import 'package:still_life/services/ml/single_item_parser.dart';

class _FakeVlmGateway implements VlmGateway {
  final bool runtime;
  final String reply;
  String? lastModelPath;
  String? lastMmprojPath;
  String? lastPrompt;
  Uint8List? lastImageBytes;

  _FakeVlmGateway({this.runtime = true, this.reply = '{}'});

  @override
  Future<bool> runtimeAvailable() async => runtime;

  @override
  Future<String> describeImage({
    required String modelPath,
    required String mmprojPath,
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    lastModelPath = modelPath;
    lastMmprojPath = mmprojPath;
    lastPrompt = prompt;
    lastImageBytes = imageBytes;
    return reply;
  }
}

void main() {
  late Directory tempDir;
  late IoOnDeviceModelStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('smolvlm_engine_test');
    store = IoOnDeviceModelStore(resolveBaseDir: () async => tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  /// Fakes a completed download of [model] (exact registry sizes on disk).
  Future<void> installModel(OnDeviceModel model) async {
    for (final f in model.files) {
      final file = File(await store.filePath(model, f));
      await file.create(recursive: true);
      final raf = file.openSync(mode: FileMode.write);
      raf.truncateSync(f.sizeBytes);
      raf.closeSync();
    }
  }

  group('SmolVlmEngine availability', () {
    test('unavailable when no model is downloaded', () async {
      final engine = SmolVlmEngine(gateway: _FakeVlmGateway(), store: store);
      expect(await engine.isAvailable(), isFalse);
    });

    test('unavailable when the native runtime cannot load, even with a '
        'downloaded model', () async {
      await installModel(kOnDeviceModels.first);
      final engine = SmolVlmEngine(
        gateway: _FakeVlmGateway(runtime: false),
        store: store,
      );
      expect(await engine.isAvailable(), isFalse);
    });

    test('available when runtime works AND a model is downloaded', () async {
      await installModel(kOnDeviceModels.first);
      final engine = SmolVlmEngine(gateway: _FakeVlmGateway(), store: store);
      expect(await engine.isAvailable(), isTrue);
      expect(engine.id, 'smolvlm');
    });
  });

  group('SmolVlmEngine analyzeImage', () {
    final photo = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 8, height: 8)),
    );

    test('sends the shared single-item prompt with the first downloaded '
        "model's text+mmproj paths", () async {
      await installModel(kOnDeviceModels.first);
      final gateway = _FakeVlmGateway(
        reply:
            '{"name": "Espresso Machine", "brand": "Gaggia", '
            '"model": "Classic Pro", "description": "semi-automatic", '
            '"category": "Appliance", "estimatedRetailPrice": 449}',
      );
      final engine = SmolVlmEngine(gateway: gateway, store: store);

      final result = await engine.analyzeImage(photo);

      expect(gateway.lastPrompt, kSingleItemAnalysisPrompt);
      expect(
        gateway.lastModelPath,
        endsWith('SmolVLM2-2.2B-Instruct-Q4_K_M.gguf'),
      );
      expect(
        gateway.lastMmprojPath,
        endsWith('mmproj-SmolVLM2-2.2B-Instruct-Q8_0.gguf'),
      );
      expect(result.itemName, 'Espresso Machine');
      expect(result.brand, 'Gaggia');
      expect(result.estimatedPrice, 449);
      expect(result.confidence, 0.6,
          reason: 'a 2B local VLM ranks below cloud (0.85) and above the '
              'raw-text fallback (0.4)');
    });

    test('prefixes existingLabel exactly like the other tiers', () async {
      await installModel(kOnDeviceModels.first);
      final gateway = _FakeVlmGateway();
      final engine = SmolVlmEngine(gateway: gateway, store: store);

      await engine.analyzeImage(photo, existingLabel: 'garage shelf');

      expect(
        gateway.lastPrompt,
        'This item has been labeled "garage shelf". '
        '$kSingleItemAnalysisPrompt',
      );
    });

    test('a rambling non-JSON reply degrades via the shared parser', () async {
      await installModel(kOnDeviceModels.first);
      final engine = SmolVlmEngine(
        gateway: _FakeVlmGateway(reply: 'It looks like some kind of machine.'),
        store: store,
      );

      final result = await engine.analyzeImage(photo);

      expect(result.itemName, 'Unknown Item');
      expect(result.confidence, 0.4);
    });

    test('throws StateError when called with no model downloaded', () {
      final engine = SmolVlmEngine(gateway: _FakeVlmGateway(), store: store);
      expect(() => engine.analyzeImage(photo), throwsStateError);
    });
  });

  group('prepareImageForVlm', () {
    test('downscales an oversized photo to the max side, preserving aspect',
        () {
      final big = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 2000, height: 1000)),
      );
      final out = img.decodeImage(prepareImageForVlm(big, maxSide: 768))!;
      expect(out.width, 768);
      expect(out.height, 384);
    });

    test('leaves small images untouched (byte-identical)', () {
      final small = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 100, height: 60)),
      );
      expect(prepareImageForVlm(small, maxSide: 768), same(small));
    });

    test('passes undecodable bytes through unchanged — the native side '
        'gets its own chance', () {
      final garbage = Uint8List.fromList(utf8.encode('not an image'));
      expect(prepareImageForVlm(garbage), same(garbage));
    });
  });
}

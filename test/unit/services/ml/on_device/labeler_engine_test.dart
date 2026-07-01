import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/on_device/labeler_engine.dart';

void main() {
  group('LabelerEngine', () {
    test('is available when the platform gate says so', () async {
      final engine = LabelerEngine(
        platformSupported: () async => true,
        labelImage: (_) async => const [],
      );
      expect(await engine.isAvailable(), isTrue);
      expect(engine.id, 'labeler');
    });

    test('is unavailable off-platform (web/iOS-unsupported builds)', () async {
      final engine = LabelerEngine(
        platformSupported: () async => false,
        labelImage: (_) async => const [],
      );
      expect(await engine.isAvailable(), isFalse);
    });

    test('turns the top-confidence label into an honest coarse result: '
        'name + category + confidence, brand/model NULL', () async {
      final engine = LabelerEngine(
        platformSupported: () async => true,
        labelImage: (_) async => const [
          DetectedLabel('Furniture', 0.61),
          DetectedLabel('Chair', 0.82),
          DetectedLabel('Couch', 0.40),
        ],
      );

      final result = await engine.analyzeImage(Uint8List(4));

      expect(result.itemName, 'Chair', reason: 'highest confidence wins');
      expect(result.category, 'Furniture');
      expect(result.confidence, 0.82);
      expect(result.brand, isNull, reason: 'a classifier must not guess');
      expect(result.model, isNull);
      expect(result.description, contains('Chair'));
      expect(
        result.description,
        contains('On-device'),
        reason: 'provenance visible so coarse output is never mistaken '
            'for VLM analysis',
      );
    });

    test('keeps the full label list in rawResponse for enrichment later',
        () async {
      final engine = LabelerEngine(
        platformSupported: () async => true,
        labelImage: (_) async => const [
          DetectedLabel('Chair', 0.82),
          DetectedLabel('Furniture', 0.61),
        ],
      );

      final result = await engine.analyzeImage(Uint8List(4));

      expect(result.rawResponse['labels'], [
        {'label': 'Chair', 'confidence': 0.82},
        {'label': 'Furniture', 'confidence': 0.61},
      ]);
      expect(result.rawResponse['engine'], 'labeler');
    });

    test('no labels above threshold degrades to a zero-confidence Unknown '
        'Item — honest, never fabricated', () async {
      final engine = LabelerEngine(
        platformSupported: () async => true,
        labelImage: (_) async => const [],
      );

      final result = await engine.analyzeImage(Uint8List(4));

      expect(result.itemName, 'Unknown Item');
      expect(result.category, 'Other');
      expect(result.confidence, 0.0);
      expect(result.rawResponse['labels'], isEmpty);
    });
  });
}

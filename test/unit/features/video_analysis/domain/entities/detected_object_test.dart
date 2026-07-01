import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';

void main() {
  group('DetectedObject', () {
    final image = Uint8List.fromList([0, 1, 2, 3]);

    test('displayName returns enhancedName when available', () {
      final obj = DetectedObject(
        id: 'det-1',
        label: 'tv',
        confidence: 0.9,
        frameImage: image,
        frameIndex: 0,
        enhancedName: 'Samsung 55" QLED TV',
      );
      expect(obj.displayName, 'Samsung 55" QLED TV');
    });

    test('displayName falls back to label when no enhancedName', () {
      final obj = DetectedObject(
        id: 'det-1',
        label: 'tv',
        confidence: 0.9,
        frameImage: image,
        frameIndex: 0,
      );
      expect(obj.displayName, 'tv');
    });

    test('copyWith creates updated copy', () {
      final obj = DetectedObject(
        id: 'det-1',
        label: 'tv',
        confidence: 0.9,
        frameImage: image,
        frameIndex: 0,
      );

      final updated = obj.copyWith(
        enhancedName: 'LG OLED',
        brand: 'LG',
        estimatedPrice: 1299.99,
        category: 'Electronics',
      );

      expect(updated.enhancedName, 'LG OLED');
      expect(updated.brand, 'LG');
      expect(updated.estimatedPrice, 1299.99);
      expect(updated.category, 'Electronics');
      // Original fields preserved
      expect(updated.id, 'det-1');
      expect(updated.label, 'tv');
      expect(updated.confidence, 0.9);
      expect(updated.frameImage, image);
      expect(updated.frameIndex, 0);
    });

    test('equality based on id', () {
      final obj1 = DetectedObject(
        id: 'det-1',
        label: 'tv',
        confidence: 0.9,
        frameImage: image,
        frameIndex: 0,
      );
      final obj2 = DetectedObject(
        id: 'det-1',
        label: 'tv',
        confidence: 0.95, // different confidence
        frameImage: image,
        frameIndex: 1,
      );
      expect(obj1, equals(obj2)); // Same id = equal
    });
  });
}

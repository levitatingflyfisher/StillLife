import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';

void main() {
  group('Detection', () {
    test('calculates area from bounding box', () {
      const detection = Detection(
        label: 'tv',
        confidence: 0.95,
        boundingBox: Rect.fromLTWH(10, 20, 100, 50),
        frameIndex: 0,
      );
      expect(detection.area, 5000.0);
    });

    test('toString includes label, confidence, and frame', () {
      const detection = Detection(
        label: 'couch',
        confidence: 0.82,
        boundingBox: Rect.fromLTWH(0, 0, 10, 10),
        frameIndex: 5,
      );
      expect(detection.toString(), contains('couch'));
      expect(detection.toString(), contains('82%'));
      expect(detection.toString(), contains('frame:5'));
    });
  });

  group('TrackedObject', () {
    test('label returns first detection label', () {
      const tracked = TrackedObject(
        id: 'obj-1',
        detections: [
          Detection(
            label: 'tv',
            confidence: 0.9,
            boundingBox: Rect.fromLTWH(10, 10, 100, 100),
            frameIndex: 0,
          ),
          Detection(
            label: 'tv',
            confidence: 0.95,
            boundingBox: Rect.fromLTWH(12, 12, 110, 110),
            frameIndex: 1,
          ),
        ],
        bestFrameIndex: 1,
        bestBoundingBox: Rect.fromLTWH(12, 12, 110, 110),
      );
      expect(tracked.label, 'tv');
      expect(tracked.frameCount, 2);
    });

    test('maxConfidence returns highest confidence across detections', () {
      const tracked = TrackedObject(
        id: 'obj-1',
        detections: [
          Detection(
            label: 'couch',
            confidence: 0.7,
            boundingBox: Rect.fromLTWH(0, 0, 50, 50),
            frameIndex: 0,
          ),
          Detection(
            label: 'couch',
            confidence: 0.92,
            boundingBox: Rect.fromLTWH(0, 0, 60, 60),
            frameIndex: 1,
          ),
          Detection(
            label: 'couch',
            confidence: 0.85,
            boundingBox: Rect.fromLTWH(0, 0, 55, 55),
            frameIndex: 2,
          ),
        ],
        bestFrameIndex: 1,
        bestBoundingBox: Rect.fromLTWH(0, 0, 60, 60),
      );
      expect(tracked.maxConfidence, 0.92);
    });
  });

  group('DetectedObject', () {
    final image = Uint8List.fromList([0, 1, 2, 3]);

    test('displayName returns enhancedName when available', () {
      final obj = DetectedObject(
        id: 'det-1',
        label: 'tv',
        confidence: 0.9,
        boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        croppedImage: image,
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
        boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        croppedImage: image,
        frameIndex: 0,
      );
      expect(obj.displayName, 'tv');
    });

    test('copyWith creates updated copy', () {
      final obj = DetectedObject(
        id: 'det-1',
        label: 'tv',
        confidence: 0.9,
        boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        croppedImage: image,
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
    });

    test('equality based on id', () {
      final obj1 = DetectedObject(
        id: 'det-1',
        label: 'tv',
        confidence: 0.9,
        boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        croppedImage: image,
        frameIndex: 0,
      );
      final obj2 = DetectedObject(
        id: 'det-1',
        label: 'tv',
        confidence: 0.95, // different confidence
        boundingBox: const Rect.fromLTWH(5, 5, 100, 100),
        croppedImage: image,
        frameIndex: 1,
      );
      expect(obj1, equals(obj2)); // Same id = equal
    });
  });
}

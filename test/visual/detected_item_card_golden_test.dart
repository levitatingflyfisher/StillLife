import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';
import 'package:still_life/features/video_analysis/presentation/widgets/detected_item_card.dart';

import 'visual_golden_helper.dart';

void main() {
  testWidgets('DetectedItemCard responsive golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'detected_item_card',
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DetectedItemCard(
              object: DetectedObject(
                id: 'obj-1',
                label: 'Camera',
                confidence: 0.95,
                boundingBox: const Rect.fromLTWH(0, 0, 100, 100),
                croppedImage: Uint8List(1),
                frameIndex: 0,
                enhancedName: 'Sony A7III Camera',
                brand: 'Sony',
                model: 'A7III',
                description: 'Digital mirrorless camera',
                estimatedPrice: 1299.99,
                category: 'Electronics',
              ),
              isConfirmed: false,
              isDeleted: false,
              onConfirm: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
      sizes: const <String, Size>{
        'phone': Size(360, 740),
        'narrow': Size(320, 740),
      },
      textScales: const <double>[1.0, 3.0],
    );
  });
}

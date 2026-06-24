import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';
import 'package:still_life/features/video_analysis/presentation/widgets/detected_item_card.dart';

void main() {
  testWidgets(
      'DetectedItemCard does not overflow at max accessibility text scale',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(3.0)),
            child: Scaffold(
              body: SafeArea(
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
                  onConfirm: () {},
                  onEdit: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // A narrow screen (≤320dp) at max accessibility text scale must not clip the
    // detail row (category chip + brand/model) off the right edge.
    expect(tester.takeException(), isNull);
  });
}

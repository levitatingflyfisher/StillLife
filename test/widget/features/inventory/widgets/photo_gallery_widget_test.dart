import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:still_life/features/inventory/domain/entities/photo.dart';
import 'package:still_life/features/inventory/presentation/widgets/photo_gallery_widget.dart';

void main() {
  final pngBytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 4, height: 4)),
  );

  Photo makePhoto(String id, {Uint8List? bytes, Uint8List? thumbBytes}) =>
      Photo(
        id: id,
        itemId: 'item1',
        filePath: '',
        bytes: bytes,
        thumbBytes: thumbBytes,
        isPrimary: id == '1',
        source: PhotoSource.gallery,
        capturedAt: DateTime(2024),
        createdAt: DateTime(2024),
        modifiedAt: DateTime(2024),
      );

  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

  group('PhotoGalleryWidget', () {
    testWidgets('renders byte-backed photos via Image.memory', (tester) async {
      await tester.pumpWidget(
        wrap(PhotoGalleryWidget(photos: [makePhoto('1', bytes: pngBytes)])),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<MemoryImage>());
    });

    testWidgets('shows a placeholder for a legacy photo with no bytes', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(PhotoGalleryWidget(photos: [makePhoto('1')])),
      );
      await tester.pump();

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows the add-photos empty state when there are no photos', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(PhotoGalleryWidget(photos: const [], onAddPhoto: () {})),
      );
      await tester.pump();

      expect(find.text('Add photos'), findsOneWidget);
    });
  });
}

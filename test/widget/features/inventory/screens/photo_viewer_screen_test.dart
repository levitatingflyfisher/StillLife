import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/domain/entities/photo.dart';
import 'package:still_life/features/inventory/presentation/screens/photo_viewer_screen.dart';

void main() {
  // Build a Photo stub whose file does NOT exist so the broken-image
  // placeholder is rendered instead (avoids needing real image files).
  Photo makePhoto(String id) => Photo(
    id: id,
    itemId: 'item1',
    filePath: '/nonexistent/photo_$id.jpg',
    isPrimary: id == '1',
    source: PhotoSource.gallery,
    capturedAt: DateTime(2024),
    createdAt: DateTime(2024),
    modifiedAt: DateTime(2024),
  );

  group('PhotoViewerScreen', () {
    testWidgets('shows broken-image icon when file does not exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: PhotoViewerScreen(photos: [makePhoto('1')])),
      );
      await tester.pump();

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('shows page counter when multiple photos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PhotoViewerScreen(
            photos: [makePhoto('1'), makePhoto('2')],
            initialIndex: 0,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('no page counter with a single photo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PhotoViewerScreen(photos: [makePhoto('1')])),
      );
      await tester.pump();

      // No "1 / 1" label for single photo
      expect(find.textContaining('/'), findsNothing);
    });

    testWidgets('opens at the correct initial page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PhotoViewerScreen(
            photos: [makePhoto('1'), makePhoto('2'), makePhoto('3')],
            initialIndex: 2,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PhotoViewerScreen(photos: [makePhoto('1')])),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('has a back button in the app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PhotoViewerScreen(photos: [makePhoto('1')]),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('InteractiveViewer is present for zoom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PhotoViewerScreen(photos: [makePhoto('1')])),
      );
      await tester.pump();

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });
}

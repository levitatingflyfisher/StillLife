import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/features/inventory/presentation/screens/receipt_viewer_screen.dart';
import 'package:still_life/features/inventory/presentation/widgets/receipt_tile.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

/// An item with a receiptId shows a small Receipt tile (store · date ·
/// total, thumbnail); tapping opens a plain viewer (full image + the OCR
/// text behind an expander). No editing, no linking UI.
void main() {
  ensureSqlite3();

  final pngBytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 4, height: 4)),
  );

  Future<AppDatabase> seededDb({bool withBytes = true}) async {
    final db = AppDatabase.memory();
    await db.into(db.receipts).insert(
          ReceiptsCompanion.insert(
            id: 'rcpt-1',
            photoPath: '',
            photoBytes: Value(withBytes ? pngBytes : null),
            storeName: const Value('Kroger'),
            purchaseDate: Value(DateTime(2026, 7, 2)),
            totalAmountCents: const Value(1648),
            ocrText: const Value('KROGER\nCoffee Beans 12.99'),
            createdAt: DateTime(2026),
          ),
        );
    return db;
  }

  Widget wrap(AppDatabase db, Widget child) => ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('shows store, date, total, and a thumbnail', (tester) async {
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(wrap(db, const ReceiptTile(receiptId: 'rcpt-1')));
    await tester.pumpAndSettle();

    expect(find.text('Receipt'), findsOneWidget);
    expect(find.textContaining('Kroger'), findsOneWidget);
    expect(find.textContaining('16.48'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('renders without a thumbnail when photo bytes are gone', (
    tester,
  ) async {
    final db = await seededDb(withBytes: false);
    addTearDown(db.close);

    await tester.pumpWidget(wrap(db, const ReceiptTile(receiptId: 'rcpt-1')));
    await tester.pumpAndSettle();

    expect(find.text('Receipt'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('renders nothing when the receipt row is missing', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(wrap(db, const ReceiptTile(receiptId: 'gone')));
    await tester.pumpAndSettle();

    expect(find.text('Receipt'), findsNothing);
  });

  testWidgets('tapping the tile opens the viewer with expandable OCR text', (
    tester,
  ) async {
    final db = await seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(wrap(db, const ReceiptTile(receiptId: 'rcpt-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(find.byType(ReceiptViewerScreen), findsOneWidget);
    // OCR text is behind an expander, collapsed by default.
    expect(find.text('KROGER\nCoffee Beans 12.99'), findsNothing);
    await tester.tap(find.textContaining('Scanned text'));
    await tester.pumpAndSettle();
    expect(find.text('KROGER\nCoffee Beans 12.99'), findsOneWidget);
  });
}

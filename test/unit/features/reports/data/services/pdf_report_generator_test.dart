import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/reports/data/services/pdf_report_generator.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../../test_setup.dart';

/// Inflates every FlateDecode content stream in [pdf] and returns the words
/// it draws (each `[(...)]TJ` operand), space-joined, so the test reads what
/// the insurer's PDF viewer would show rather than an intermediate value.
String _pdfDrawnText(Uint8List pdf) {
  final raw = latin1.decode(pdf);
  final words = <String>[];
  final streamStart = RegExp(r'stream\r?\n');
  final drawn = RegExp(r'\[\((.*?)\)\]TJ');
  var from = 0;
  while (true) {
    final m = streamStart.firstMatch(raw.substring(from));
    if (m == null) break;
    final begin = from + m.end;
    final end = raw.indexOf('endstream', begin);
    if (end < 0) break;
    try {
      final content = latin1.decode(
        ZLibCodec().decode(pdf.sublist(begin, end)),
        allowInvalid: true,
      );
      words.addAll(drawn.allMatches(content).map((w) => w.group(1)!));
    } on FormatException {
      // Not a deflated stream (e.g. an image or font); skip.
    }
    from = end + 'endstream'.length;
  }
  return words.join(' ');
}

void main() {
  ensureSqlite3();

  late AppDatabase db;
  final now = DateTime(2025, 6, 1);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'prop-t',
            name: 'Test Home',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room-t',
            propertyId: 'prop-t',
            name: 'Den',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-t',
            name: 'Electronics',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'item-t',
            name: 'Record player',
            categoryId: 'cat-t',
            roomId: 'room-t',
            createdAt: now,
            modifiedAt: now,
            currentValueCents: const Value(12345),
            replacementCostCents: const Value(6789),
            purchasePriceCents: const Value(1001),
          ),
        );
  });

  tearDown(() => db.close());

  test(
    'prints stored integer cents as dollars, never cents-as-dollars',
    () async {
      final bytes = await PdfReportGenerator(
        db,
      ).generateReport(propertyId: 'prop-t');
      final text = _pdfDrawnText(bytes);

      // Cover total, summary row, category row, room subtotal, item row.
      expect(text, contains(r'Total Value: $123.45'));
      expect(text, contains(r'Total Current Value $123.45'));
      expect(text, contains(r'Total Replacement Cost $67.89'));
      expect(text, contains(r'Total Acquisition Cost $10.01'));
      expect(text, contains(r'Category Total Value Electronics $123.45'));
      expect(text, contains(r'Subtotal: $123.45'));
      expect(text, contains(r'Record player Electronics $123.45 $67.89'));
      expect(text, isNot(contains(r'$12,345.00')));
      expect(text, isNot(contains(r'$6,789.00')));
      expect(text, isNot(contains(r'$1,001.00')));
    },
  );
}

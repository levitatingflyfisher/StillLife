import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/import/domain/parsed_import_item.dart';
import 'package:still_life/services/import/import_receipt_ocr_service.dart';

// Test subclass that bypasses hardware MLKit and file I/O.
class _TestOcrService extends ImportReceiptOcrService {
  final String fakeOcrText;
  final Uint8List fakeBytes;

  _TestOcrService({
    required this.fakeOcrText,
    Uint8List? fakeBytes,
    super.providerManager, // ignore: unused_element_parameter
  }) : fakeBytes = fakeBytes ?? Uint8List(0);

  @override
  Future<String> extractOcrText(File file) async => fakeOcrText;

  @override
  Future<Uint8List> readFileBytes(File file) async => fakeBytes;
}

void main() {
  // Tests use _TestOcrService with no real LLM (providerManager = null).
  // LLM path is skipped when providerManager is null.

  test(
    'parseReceipt extracts item and price from OCR text via regex',
    () async {
      final service = _TestOcrService(
        fakeOcrText: '''
WALMART
Coffee Beans  \$12.99
Dish Soap     \$3.49
Total         \$16.48
''',
      );
      final file = File('dummy.jpg');
      final items = await service.parseReceipt(file);
      expect(items.length, greaterThanOrEqualTo(2));
      expect(
        items.any((i) => i.name.contains('Coffee') && i.price == 12.99),
        isTrue,
      );
      expect(
        items.any((i) => i.name.contains('Dish') && i.price == 3.49),
        isTrue,
      );
    },
  );

  test('parseReceipt sets source to ImportSource.receipt', () async {
    final service = _TestOcrService(fakeOcrText: 'Widget  \$5.00\n');
    final items = await service.parseReceipt(File('dummy.jpg'));
    expect(items.every((i) => i.source == ImportSource.receipt), isTrue);
  });

  test('parseReceipt skips Total/Subtotal/Tax lines', () async {
    final service = _TestOcrService(
      fakeOcrText: '''
Coffee  \$5.00
Total   \$5.00
Tax     \$0.40
Subtotal \$5.00
''',
    );
    final items = await service.parseReceipt(File('dummy.jpg'));
    expect(
      items.every((i) => !i.name.toLowerCase().startsWith('total')),
      isTrue,
    );
    expect(items.every((i) => !i.name.toLowerCase().startsWith('tax')), isTrue);
    expect(
      items.every((i) => !i.name.toLowerCase().startsWith('subtotal')),
      isTrue,
    );
  });

  test('parseReceipt returns empty list for empty OCR text', () async {
    final service = _TestOcrService(fakeOcrText: '');
    final items = await service.parseReceipt(File('dummy.jpg'));
    expect(items, isEmpty);
  });

  test('parseReceipt returns empty list when no price lines found', () async {
    final service = _TestOcrService(
      fakeOcrText: 'STORE NAME\nThank you for shopping\n',
    );
    final items = await service.parseReceipt(File('dummy.jpg'));
    expect(items, isEmpty);
  });

  test('extractOcrText is overridable (@visibleForTesting)', () async {
    final service = _TestOcrService(fakeOcrText: 'test text');
    expect(await service.extractOcrText(File('dummy.jpg')), 'test text');
  });

  test('readFileBytes is overridable (@visibleForTesting)', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final service = _TestOcrService(fakeOcrText: '', fakeBytes: bytes);
    expect(await service.readFileBytes(File('dummy.jpg')), bytes);
  });
}

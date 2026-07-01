import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/settings/presentation/screens/settings_screen.dart';
import 'package:still_life/services/import/import_receipt_ocr_service.dart';

/// Camera/gallery fake: always "picks" the same tiny photo.
class _FakeImagePickerPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      XFile.fromData(Uint8List.fromList([1, 2, 3]), path: '/tmp/fake.jpg');
}

/// File-picker fake that returns a canned CSV.
class _FakeFilePicker extends FilePicker {
  final Uint8List? bytes;
  _FakeFilePicker(this.bytes);

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    @Deprecated('deprecated upstream') bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    final b = bytes;
    if (b == null) return null;
    return FilePickerResult([
      PlatformFile(name: 'orders.csv', size: b.length, bytes: b),
    ]);
  }
}

/// OCR-service stub with a controllable completion.
class _StubOcrService extends ImportReceiptOcrService {
  final Future<ReceiptImportResult> Function() onParse;
  _StubOcrService(this.onParse);

  @override
  Future<ReceiptImportResult> parseReceipt(String imagePath) => onParse();
}

ReceiptImportResult _emptyResult() => const ReceiptImportResult(
  items: [],
  ocrText: 'blurry noise',
  engine: ReceiptParseEngine.deterministic,
  engineLabel: 'Pattern-matched',
);

void main() {
  Widget buildSubject({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  Future<void> openImportSheet(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Import items'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Import items'));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty receipt parse SAYS so instead of silently doing '
      'nothing', (tester) async {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform();
    await tester.pumpWidget(
      buildSubject(
        overrides: [
          receiptOcrServiceProvider.overrideWithValue(
            _StubOcrService(() async => _emptyResult()),
          ),
        ],
      ),
    );

    await openImportSheet(tester);
    await tester.tap(find.text('Receipt photo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No items found on the receipt'),
        findsOneWidget,
        reason: 'the sheet just closed — with no feedback the feature '
            'reads as simply broken');
  });

  testWidgets('receipt parsing shows a progress indicator while OCR + LLM '
      'run', (tester) async {
    ImagePickerPlatform.instance = _FakeImagePickerPlatform();
    final gate = Completer<ReceiptImportResult>();
    await tester.pumpWidget(
      buildSubject(
        overrides: [
          receiptOcrServiceProvider.overrideWithValue(
            _StubOcrService(() => gate.future),
          ),
        ],
      ),
    );

    await openImportSheet(tester);
    await tester.tap(find.text('Receipt photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: 'a multi-second OCR + LLM call with nothing on screen '
            'looks like a frozen app');

    gate.complete(_emptyResult());
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('an Amazon CSV with no recognizable orders SAYS so',
      (tester) async {
    FilePicker.platform = _FakeFilePicker(
      Uint8List.fromList(utf8.encode('foo,bar\n1,2\n')),
    );
    await tester.pumpWidget(buildSubject());

    await openImportSheet(tester);
    await tester.tap(find.text('Amazon order export'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No orders found'), findsOneWidget,
        reason: 'picking the wrong CSV from the Privacy Central ZIP must '
            'not dead-end in silence');
  });
}

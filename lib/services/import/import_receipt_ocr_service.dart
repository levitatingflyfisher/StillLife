import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../features/import/domain/parsed_import_item.dart';
import '../ml/provider_manager.dart';

/// Three-stage receipt OCR pipeline:
/// 1. MLKit text recognition (`extractOcrText`) — overridable in tests
/// 2. LLM enhancement via [ProviderManager] — reserved for future image-based
///    enhancement; currently falls through to regex stage
/// 3. Regex fallback supplement
class ImportReceiptOcrService {
  final ProviderManager? providerManager;

  ImportReceiptOcrService({this.providerManager});

  /// Extracts raw OCR text from [file] using MLKit.
  ///
  /// Override in tests via a subclass to bypass hardware dependency.
  @visibleForTesting
  Future<String> extractOcrText(File file) async {
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      textRecognizer.close();
    }
  }

  /// Reads raw bytes from [file].
  ///
  /// Override in tests to bypass real file I/O.
  @visibleForTesting
  Future<Uint8List> readFileBytes(File file) => file.readAsBytes();

  /// Parses a receipt image [file] and returns extracted [ParsedImportItem]s.
  Future<List<ParsedImportItem>> parseReceipt(File file) async {
    // Stage 1: OCR
    String ocrText;
    try {
      ocrText = await extractOcrText(file);
    } catch (_) {
      ocrText = '';
    }

    // Stage 2: LLM enhancement (reserved for future image-based LLM path).
    // ProviderManager exposes analyzeImage; a text-generation API is not yet
    // available, so this stage is a no-op and falls through to regex.
    final String enhancedText = ocrText;

    // Stage 3: Regex extraction
    return _extractItemsWithRegex(enhancedText);
  }

  static final _skipPattern = RegExp(
    r'^\s*(total|subtotal|tax|tip|change|cash|credit|debit|balance|amount due)',
    caseSensitive: false,
  );

  static final _itemPricePattern = RegExp(
    r'^(.+?)\s+\$?([\d,]+\.?\d{0,2})\s*$',
  );

  List<ParsedImportItem> _extractItemsWithRegex(String text) {
    final items = <ParsedImportItem>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (_skipPattern.hasMatch(trimmed)) continue;

      final match = _itemPricePattern.firstMatch(trimmed);
      if (match == null) continue;

      final name = match.group(1)!.trim();
      final price = double.tryParse(match.group(2)!.replaceAll(',', ''));
      if (name.isEmpty || price == null) continue;

      items.add(
        ParsedImportItem(
          name: name,
          price: price,
          source: ImportSource.receipt,
        ),
      );
    }
    return items;
  }
}

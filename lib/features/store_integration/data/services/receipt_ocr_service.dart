import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:still_life/features/store_integration/domain/entities/receipt.dart';

class ReceiptParseResult {
  final String? storeName;
  final DateTime? purchaseDate;
  final double? totalAmount;
  final List<ReceiptLineItem> lineItems;
  final String rawText;

  const ReceiptParseResult({
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    this.lineItems = const [],
    required this.rawText,
  });
}

class ReceiptOcrService {
  static final _datePatterns = [
    // MM/DD/YYYY or MM-DD-YYYY
    RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'),
    // YYYY-MM-DD
    RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'),
    // MM/DD/YY
    RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2})\b'),
  ];

  static final _pricePattern = RegExp(r'\$?\s*(\d+\.\d{2})\s*$');
  static final _totalPattern = RegExp(
    r'(?:total|amount\s*due|balance)',
    caseSensitive: false,
  );

  Future<ReceiptParseResult> processReceipt(String imagePath) async {
    final recognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognized = await recognizer.processImage(inputImage);
      final rawText = recognized.text;
      final lines = rawText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      return ReceiptParseResult(
        storeName: _extractStoreName(lines),
        purchaseDate: _extractDate(lines),
        totalAmount: _extractTotal(lines),
        lineItems: _extractLineItems(lines),
        rawText: rawText,
      );
    } finally {
      await recognizer.close();
    }
  }

  String? _extractStoreName(List<String> lines) {
    if (lines.isEmpty) return null;
    // First non-empty line is typically the store name
    for (final line in lines.take(3)) {
      if (!_pricePattern.hasMatch(line) &&
          !_totalPattern.hasMatch(line) &&
          !_datePatterns.any((p) => p.hasMatch(line))) {
        return line;
      }
    }
    return null;
  }

  DateTime? _extractDate(List<String> lines) {
    for (final line in lines) {
      for (var i = 0; i < _datePatterns.length; i++) {
        final match = _datePatterns[i].firstMatch(line);
        if (match == null) continue;
        try {
          switch (i) {
            case 0: // MM/DD/YYYY
              return DateTime(
                int.parse(match.group(3)!),
                int.parse(match.group(1)!),
                int.parse(match.group(2)!),
              );
            case 1: // YYYY-MM-DD
              return DateTime(
                int.parse(match.group(1)!),
                int.parse(match.group(2)!),
                int.parse(match.group(3)!),
              );
            case 2: // MM/DD/YY
              final year = 2000 + int.parse(match.group(3)!);
              return DateTime(
                year,
                int.parse(match.group(1)!),
                int.parse(match.group(2)!),
              );
          }
        } catch (_) {
          // Invalid date values, continue searching
        }
      }
    }
    return null;
  }

  double? _extractTotal(List<String> lines) {
    for (final line in lines.reversed) {
      if (_totalPattern.hasMatch(line)) {
        final priceMatch = _pricePattern.firstMatch(line);
        if (priceMatch != null) {
          return double.tryParse(priceMatch.group(1)!);
        }
        // Price might be on the same line after "TOTAL" but in a different format
        final inlinePrice = RegExp(r'(\d+\.\d{2})').firstMatch(line);
        if (inlinePrice != null) {
          return double.tryParse(inlinePrice.group(1)!);
        }
      }
    }
    return null;
  }

  List<ReceiptLineItem> _extractLineItems(List<String> lines) {
    final items = <ReceiptLineItem>[];
    for (final line in lines) {
      if (_totalPattern.hasMatch(line)) continue;

      final priceMatch = _pricePattern.firstMatch(line);
      if (priceMatch != null) {
        final description = line.substring(0, priceMatch.start).trim();
        if (description.isNotEmpty) {
          items.add(
            ReceiptLineItem(
              description: description,
              price: double.tryParse(priceMatch.group(1)!),
            ),
          );
        }
      }
    }
    return items;
  }
}

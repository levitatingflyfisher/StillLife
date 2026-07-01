import 'dart:convert';

import 'package:still_life/services/ml/analysis_provider.dart';

/// The canonical single-item analysis prompt. Every tier that asks a model
/// to identify ONE item sends this exact text — it was previously
/// copy-pasted into each provider, which is how prompt/parser drift starts.
const String kSingleItemAnalysisPrompt = '''
Analyze this image of a household item. Respond ONLY with a JSON object (no markdown, no explanation) with these fields:
{
  "name": "item name",
  "brand": "brand name or null",
  "model": "model number/name or null",
  "description": "brief description of the item",
  "category": "one of: Electronics, Furniture, Appliance, Clothing, Kitchenware, Decor, Tool, Book, Toy, Sporting Goods, Jewelry, Art, Musical Instrument, Other",
  "estimatedRetailPrice": estimated price as a number or null
}
''';

/// Parses a model's single-item reply into an [AnalysisResult].
///
/// Extracts the first `{...}` block (models love wrapping JSON in prose or
/// markdown fences), decodes it guardedly, and fills honest defaults for
/// missing fields. Malformed or truncated output degrades to a
/// low-confidence raw-text result — never a crash, never fabricated fields.
/// [confidence] is the provider's trust level for a successful parse; the
/// fallback always reports 0.4.
AnalysisResult parseSingleItemResponse(
  String responseText, {
  required double confidence,
}) {
  final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
  if (jsonMatch != null) {
    try {
      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      return AnalysisResult(
        itemName: json['name'] as String? ?? 'Unknown Item',
        brand: json['brand'] as String?,
        model: json['model'] as String?,
        description: json['description'] as String? ?? responseText,
        category: json['category'] as String? ?? 'Other',
        estimatedPrice: parseFlexiblePrice(json['estimatedRetailPrice']),
        confidence: confidence,
        rawResponse: json,
      );
    } on FormatException {
      // Fall through to the raw-text fallback.
    }
  }

  return AnalysisResult(
    itemName: 'Unknown Item',
    description: responseText.trim(),
    category: 'Other',
    confidence: 0.4,
    rawResponse: {'raw_text': responseText},
  );
}

/// Accepts a price as a number, a currency string ("\$1,299.99"), or null.
double? parseFlexiblePrice(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
  }
  return null;
}

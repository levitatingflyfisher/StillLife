import 'dart:convert';

import 'package:still_life/services/ml/analysis_provider.dart';

/// Hard cap on how many items one shelf photo may yield — keeps a
/// hallucinating model from flooding the review screen. Raising it means
/// raising [kMultiItemMaxTokens] too: a truncated JSON array parses as
/// nothing, so the output budget must always cover a full-cap reply.
const int kMultiItemCap = 50;

/// Output-token budget every provider must request for a multi-item call.
/// Sized to the cap (~55 tokens per item object, with headroom): a reply
/// truncated by max_tokens loses the closing bracket and the whole array
/// parses as zero items, so under-budgeting silently destroys results.
const int kMultiItemMaxTokens = 4000;

/// Shared prompt for one-photo-many-items ("shelf") analysis. Every tier
/// sends this alongside the photo; the parsers below understand the shape
/// it asks for.
const String kMultiItemAnalysisPrompt = '''
Identify EACH distinct physical item visible in this photo of a shelf or room.
Respond ONLY with a compact JSON array (no markdown, no explanation), one object per item:
[{"name": "item name", "brand": "brand or null — only when clearly legible on the item, do not guess from partial text", "model": "model number/name or null — same rule, do not guess", "category": "one of: Electronics, Furniture, Appliances, Clothing, Tools, Sports, Books, Kitchenware, Other", "estimatedRetailPrice": number or null, "confidence": number between 0 and 1}]
List at most $kMultiItemCap items.
''';

/// Parses a model's multi-item reply into a list of [AnalysisResult]s,
/// defensively:
///
/// - guarded [jsonDecode] — malformed output yields an empty list, never
///   a crash;
/// - tolerates a bare array, a wrapped `{"items": [...]}` object (what
///   `response_format: json_object` forces), and a single bare item object;
/// - drops malformed entries (non-objects, missing/empty name) while
///   keeping the good ones;
/// - coerces sloppy field types (numeric brand, string price, non-numeric
///   confidence) instead of throwing;
/// - caps the list at [kMultiItemCap].
List<AnalysisResult> parseMultiItemResponse(
  String responseText, {
  required double defaultConfidence,
}) {
  final entries = _extractEntries(responseText);
  if (entries == null) return const [];

  final results = <AnalysisResult>[];
  for (final entry in entries) {
    if (results.length >= kMultiItemCap) break;
    if (entry is! Map<String, dynamic>) continue;

    final name = entry['name'];
    if (name is! String || name.trim().isEmpty) continue;

    results.add(
      AnalysisResult(
        itemName: name.trim(),
        brand: _cleanString(entry['brand']),
        model: _cleanString(entry['model']),
        description: _cleanString(entry['description']) ?? '',
        category: _cleanString(entry['category']) ?? 'Other',
        estimatedPrice: _parsePrice(entry['estimatedRetailPrice']),
        confidence: _parseConfidence(entry['confidence'], defaultConfidence),
        rawResponse: entry,
      ),
    );
  }
  return results;
}

/// Finds the list of candidate item entries in [text], trying the bare
/// array first, then the wrapped object, then a lone item object.
List<dynamic>? _extractEntries(String text) {
  final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
  if (arrayMatch != null) {
    try {
      final decoded = jsonDecode(arrayMatch.group(0)!);
      if (decoded is List) return decoded;
    } on FormatException {
      // Fall through to the object shapes.
    }
  }

  final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
  if (objectMatch != null) {
    try {
      final decoded = jsonDecode(objectMatch.group(0)!);
      if (decoded is Map<String, dynamic>) {
        final items = decoded['items'];
        if (items is List) return items;
        // A lone item object is treated as a one-item list.
        if (decoded['name'] is String) return [decoded];
      }
    } on FormatException {
      // Unparseable — treated as no entries.
    }
  }

  return null;
}

String? _cleanString(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _parsePrice(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
  }
  return null;
}

double _parseConfidence(dynamic value, double fallback) {
  if (value is num) return value.toDouble().clamp(0.0, 1.0);
  return fallback;
}

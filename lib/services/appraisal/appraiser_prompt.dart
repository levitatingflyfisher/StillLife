import '../../features/appraisal/domain/entities/appraisal.dart';
import '../../features/inventory/domain/entities/item.dart';

/// Pure functions that assemble the Anthropic Messages request for the
/// Appraiser feature. No IO / no Riverpod.
class AppraiserPrompt {
  static const String systemPromptBase = '''
You are a household inventory appraiser. Respond with ONLY this JSON object — no prose, no markdown fence:

{"value": <number>, "currency": "USD", "confidence": <0.0-1.0>, "sources": [{"url": "<href>", "title": "<page title>", "price": <number?>}]}

If you cannot find comparable listings, return {"value": 0, "currency": "USD", "confidence": 0.0, "sources": []}.
Never hallucinate prices. Always cite URLs when using search.
''';

  static String modeInstruction(AppraisalMode mode) {
    switch (mode) {
      case AppraisalMode.resale:
        return 'Estimate resale value today. Use secondary-market domains only.';
      case AppraisalMode.replaceNew:
        return 'Estimate retail price to buy this item brand new today.';
      case AppraisalMode.replaceEquivalent:
        return 'Estimate cost to replace with equivalent-age, equivalent-condition item. Apply age/condition discount.';
    }
  }

  static List<String> allowedDomains(AppraisalMode mode) {
    switch (mode) {
      case AppraisalMode.resale:
        return ['ebay.com', 'craigslist.org'];
      case AppraisalMode.replaceNew:
        return ['amazon.com', 'walmart.com', 'bestbuy.com', 'target.com'];
      case AppraisalMode.replaceEquivalent:
        return ['amazon.com', 'ebay.com'];
    }
  }

  /// Human-readable description of the item, fed to the LLM as the user turn.
  static String itemDescription(Item item) {
    final parts = <String>[
      'Name: ${item.name}',
      if ((item.description).isNotEmpty) 'Description: ${item.description}',
      if (item.condition != null) 'Condition: ${item.condition!.label}',
      if (item.purchaseDate != null) 'Purchased: ${item.purchaseDate!.year}',
      if ((item.notes ?? '').isNotEmpty) 'Notes: ${item.notes}',
      if ((item.serialNumber ?? '').isNotEmpty) 'Serial: ${item.serialNumber}',
    ];
    return parts.join('\n');
  }

  /// Deterministic cache key. Uses `<brand>|<model>|<condition>` when brand
  /// and model are encoded in the description/notes; otherwise falls back to
  /// `<name>|<condition>`.
  static String itemModelKey(Item item) {
    final name = item.name.trim().toLowerCase();
    final condition = item.condition?.label.toLowerCase() ?? 'unknown';
    return '$name|$condition';
  }

  /// Builds the full Anthropic Messages request body for a given item + mode.
  static Map<String, dynamic> buildRequest({
    required Item item,
    required AppraisalMode mode,
    required String countryCode,
    int maxTokens = 800,
    String model = 'claude-sonnet-4-20250514',
  }) {
    final system = '$systemPromptBase\n\n${modeInstruction(mode)}';
    final user = itemDescription(item);
    return {
      'model': model,
      'max_tokens': maxTokens,
      'system': system,
      'messages': [
        {'role': 'user', 'content': user},
      ],
      'tools': [
        {
          'type': 'web_search_20250305',
          'name': 'web_search',
          'max_uses': 3,
          'allowed_domains': allowedDomains(mode),
          'user_location': {'type': 'approximate', 'country': countryCode},
        },
      ],
    };
  }
}

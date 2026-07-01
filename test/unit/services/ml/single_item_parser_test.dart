import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/single_item_parser.dart';

void main() {
  group('kSingleItemAnalysisPrompt', () {
    test('is the canonical prompt the providers were duplicating', () {
      expect(
        kSingleItemAnalysisPrompt,
        contains('Respond ONLY with a JSON object'),
      );
      expect(kSingleItemAnalysisPrompt, contains('"estimatedRetailPrice"'));
      expect(
        kSingleItemAnalysisPrompt,
        contains(
          'one of: Electronics, Furniture, Appliance, Clothing, '
          'Kitchenware, Decor, Tool, Book, Toy, Sporting Goods, Jewelry, '
          'Art, Musical Instrument, Other',
        ),
      );
    });
  });

  group('parseSingleItemResponse', () {
    test('parses a complete JSON object with numeric price', () {
      final r = parseSingleItemResponse(
        '{"name": "Bosch Drill", "brand": "Bosch", "model": "GSB 18V-55", '
        '"description": "18V combi drill", "category": "Tool", '
        '"estimatedRetailPrice": 129.99}',
        confidence: 0.6,
      );

      expect(r.itemName, 'Bosch Drill');
      expect(r.brand, 'Bosch');
      expect(r.model, 'GSB 18V-55');
      expect(r.description, '18V combi drill');
      expect(r.category, 'Tool');
      expect(r.estimatedPrice, 129.99);
      expect(r.confidence, 0.6);
    });

    test('extracts the JSON object out of surrounding prose/markdown', () {
      final r = parseSingleItemResponse(
        'Sure! Here is the analysis:\n```json\n'
        '{"name": "Kettle", "brand": null, "model": null, '
        '"description": "electric kettle", "category": "Kitchenware", '
        '"estimatedRetailPrice": null}\n```\nHope that helps.',
        confidence: 0.85,
      );

      expect(r.itemName, 'Kettle');
      expect(r.brand, isNull);
      expect(r.category, 'Kitchenware');
      expect(r.estimatedPrice, isNull);
    });

    test('parses a price given as a currency string', () {
      final r = parseSingleItemResponse(
        '{"name": "TV", "description": "", "category": "Electronics", '
        '"estimatedRetailPrice": "\$1,299.99"}',
        confidence: 0.85,
      );
      expect(r.estimatedPrice, 1299.99);
    });

    test('fills honest defaults for missing fields', () {
      final r = parseSingleItemResponse(
        '{"brand": "Sony"}',
        confidence: 0.85,
      );
      expect(r.itemName, 'Unknown Item');
      expect(r.category, 'Other');
      expect(r.brand, 'Sony');
    });

    test(
      'malformed output degrades to a low-confidence raw-text result — '
      'never a crash, never fabricated fields',
      () {
        final r = parseSingleItemResponse(
          'I cannot identify this item.',
          confidence: 0.85,
        );

        expect(r.itemName, 'Unknown Item');
        expect(r.description, 'I cannot identify this item.');
        expect(r.category, 'Other');
        expect(r.confidence, 0.4, reason: 'fallback ignores caller confidence');
        expect(r.rawResponse, {'raw_text': 'I cannot identify this item.'});
      },
    );

    test('truncated JSON (unclosed brace) also degrades to the fallback', () {
      final r = parseSingleItemResponse(
        '{"name": "Lamp", "brand": "IK',
        confidence: 0.85,
      );
      expect(r.itemName, 'Unknown Item');
      expect(r.confidence, 0.4);
    });
  });
}

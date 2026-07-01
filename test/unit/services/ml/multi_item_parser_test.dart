import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/multi_item_parser.dart';

void main() {
  group('parseMultiItemResponse — happy paths', () {
    test('parses a bare JSON array into one result per item', () {
      const text =
          '[{"name":"Bosch Drill","brand":"Bosch","model":"GSB 18V-55",'
          '"category":"Tools","estimatedRetailPrice":129.99,"confidence":0.9},'
          '{"name":"Paperback","brand":null,"model":null,"category":"Books",'
          '"estimatedRetailPrice":null,"confidence":0.6}]';

      final results = parseMultiItemResponse(text, defaultConfidence: 0.7);

      expect(results, hasLength(2));
      expect(results[0].itemName, 'Bosch Drill');
      expect(results[0].brand, 'Bosch');
      expect(results[0].model, 'GSB 18V-55');
      expect(results[0].category, 'Tools');
      expect(results[0].estimatedPrice, 129.99);
      expect(results[0].confidence, 0.9);
      expect(results[1].itemName, 'Paperback');
      expect(results[1].brand, isNull);
      expect(results[1].estimatedPrice, isNull);
    });

    test('tolerates markdown fences and prose around the array', () {
      const text =
          'Here are the items I can see:\n```json\n'
          '[{"name":"Vase","category":"Kitchenware"}]\n```\nHope that helps!';

      final results = parseMultiItemResponse(text, defaultConfidence: 0.7);

      expect(results, hasLength(1));
      expect(results.single.itemName, 'Vase');
    });

    test('tolerates the wrapped {"items":[...]} object shape that '
        'json_object response mode forces', () {
      const text = '{"items":[{"name":"Desk Lamp","category":"Other"}]}';

      final results = parseMultiItemResponse(text, defaultConfidence: 0.7);

      expect(results, hasLength(1));
      expect(results.single.itemName, 'Desk Lamp');
    });

    test('tolerates a single bare item object as a one-item list', () {
      const text = '{"name":"Lone Mug","category":"Kitchenware"}';

      final results = parseMultiItemResponse(text, defaultConfidence: 0.7);

      expect(results, hasLength(1));
      expect(results.single.itemName, 'Lone Mug');
    });
  });

  group('parseMultiItemResponse — defensive behavior', () {
    test('drops malformed entries but keeps the good ones', () {
      const text =
          '[{"name":"Good Item","category":"Tools"},'
          '"just a string",'
          '{"category":"Tools"},'
          '{"name":"","category":"Tools"},'
          '{"name":"Another Good One"}]';

      final results = parseMultiItemResponse(text, defaultConfidence: 0.7);

      expect(results, hasLength(2));
      expect(results[0].itemName, 'Good Item');
      expect(results[1].itemName, 'Another Good One');
    });

    test('unparseable garbage yields an empty list, never a throw', () {
      expect(parseMultiItemResponse('no json here', defaultConfidence: 0.7),
          isEmpty);
      expect(parseMultiItemResponse('[{broken json]', defaultConfidence: 0.7),
          isEmpty);
      expect(parseMultiItemResponse('', defaultConfidence: 0.7), isEmpty);
    });

    test('caps the list at 50 items', () {
      final entries = List.generate(80, (i) => '{"name":"Item $i"}');
      final text = '[${entries.join(',')}]';

      final results = parseMultiItemResponse(text, defaultConfidence: 0.7);

      expect(results, hasLength(50));
      expect(results.first.itemName, 'Item 0');
      expect(results.last.itemName, 'Item 49');
    });

    test('coerces sloppy field types instead of crashing', () {
      const text =
          '[{"name":"TV","brand":42,"model":true,"category":7,'
          '"estimatedRetailPrice":"\$1,299.99","confidence":"high"}]';

      final results = parseMultiItemResponse(text, defaultConfidence: 0.7);

      expect(results, hasLength(1));
      final r = results.single;
      expect(r.brand, isNull, reason: 'non-string brand must not crash');
      expect(r.model, isNull);
      expect(r.category, 'Other');
      expect(r.estimatedPrice, 1299.99);
      expect(r.confidence, 0.7,
          reason: 'unparseable confidence falls back to the default');
    });

    test('clamps out-of-range confidence into [0, 1] and normalizes '
        'empty brand/model to null', () {
      const text =
          '[{"name":"A","confidence":3.5,"brand":"","model":"  "},'
          '{"name":"B","confidence":-1}]';

      final results = parseMultiItemResponse(text, defaultConfidence: 0.7);

      expect(results[0].confidence, 1.0);
      expect(results[0].brand, isNull);
      expect(results[0].model, isNull);
      expect(results[1].confidence, 0.0);
    });
  });

  group('kMultiItemAnalysisPrompt contract', () {
    test('asks for every distinct item, honest brand/model, a compact '
        'JSON array, and the item cap', () {
      final p = kMultiItemAnalysisPrompt.toLowerCase();
      expect(p, contains('each distinct'));
      expect(p, contains('json array'));
      expect(p, contains('do not guess'));
      expect(p, contains('confidence'));
    });

    test('the output-token budget covers a full-cap reply', () {
      // ~55 output tokens per item object in practice; 70/item leaves
      // headroom so a max-length reply can't truncate mid-array (a
      // truncated array parses as zero items — total loss).
      expect(kMultiItemMaxTokens, greaterThanOrEqualTo(kMultiItemCap * 70));
    });

    test('the prompt cap can never drift from kMultiItemCap', () {
      expect(kMultiItemCap, 50);
      expect(
        kMultiItemAnalysisPrompt,
        contains('List at most $kMultiItemCap items'),
        reason: 'the prompt must interpolate the cap constant, not '
            'hardcode a number that silently diverges from the parser',
      );
    });

    test('offers exactly the nine known categories', () {
      for (final c in [
        'Electronics',
        'Furniture',
        'Appliances',
        'Clothing',
        'Tools',
        'Sports',
        'Books',
        'Kitchenware',
        'Other',
      ]) {
        expect(kMultiItemAnalysisPrompt, contains(c));
      }
    });
  });
}

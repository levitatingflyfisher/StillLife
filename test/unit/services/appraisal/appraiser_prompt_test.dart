import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/appraisal/domain/entities/appraisal.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/services/appraisal/appraiser_prompt.dart';

void main() {
  Item sampleItem({
    String name = 'Samsung TV',
    ItemCondition? condition = ItemCondition.good,
  }) => Item(
    id: 'i1',
    name: name,
    description: '55-inch LED',
    categoryId: 'cat',
    roomId: 'room',
    condition: condition,
    createdAt: DateTime(2024, 1, 1),
    modifiedAt: DateTime(2024, 1, 1),
  );

  group('AppraiserPrompt.buildRequest', () {
    test('includes model, messages, and web_search tool', () {
      final req = AppraiserPrompt.buildRequest(
        item: sampleItem(),
        mode: AppraisalMode.resale,
        countryCode: 'US',
      );
      expect(req['model'], isA<String>());
      expect(req['messages'], isA<List>());
      expect(req['tools'], isA<List>());
      final tools = req['tools'] as List;
      expect(tools, isNotEmpty);
      final tool = tools.first as Map<String, dynamic>;
      expect(tool['type'], 'web_search_20250305');
      expect(tool['user_location'], {'type': 'approximate', 'country': 'US'});
    });

    test('resale mode uses secondary-market allowed_domains', () {
      final req = AppraiserPrompt.buildRequest(
        item: sampleItem(),
        mode: AppraisalMode.resale,
        countryCode: 'US',
      );
      final tool = (req['tools'] as List).first as Map<String, dynamic>;
      final domains = tool['allowed_domains'] as List;
      expect(domains, contains('ebay.com'));
      expect(domains, contains('craigslist.org'));
      expect(domains, isNot(contains('amazon.com')));
    });

    test('replace_new mode uses retail allowed_domains', () {
      final req = AppraiserPrompt.buildRequest(
        item: sampleItem(),
        mode: AppraisalMode.replaceNew,
        countryCode: 'US',
      );
      final tool = (req['tools'] as List).first as Map<String, dynamic>;
      final domains = tool['allowed_domains'] as List;
      expect(domains, containsAll(['amazon.com', 'walmart.com']));
    });

    test('system prompt contains mode-specific instruction', () {
      final req = AppraiserPrompt.buildRequest(
        item: sampleItem(),
        mode: AppraisalMode.resale,
        countryCode: 'US',
      );
      final system = req['system'] as String;
      expect(system, contains('resale value'));
    });
  });

  group('AppraiserPrompt.itemModelKey', () {
    test('is deterministic for identical inputs', () {
      final a = AppraiserPrompt.itemModelKey(sampleItem());
      final b = AppraiserPrompt.itemModelKey(sampleItem());
      expect(a, b);
    });

    test('differs when condition changes', () {
      final a = AppraiserPrompt.itemModelKey(sampleItem());
      final b = AppraiserPrompt.itemModelKey(
        sampleItem(condition: ItemCondition.fair),
      );
      expect(a, isNot(b));
    });

    test('includes name + condition', () {
      final k = AppraiserPrompt.itemModelKey(sampleItem());
      expect(k, contains('samsung tv'));
      expect(k, contains('good'));
    });
  });
}

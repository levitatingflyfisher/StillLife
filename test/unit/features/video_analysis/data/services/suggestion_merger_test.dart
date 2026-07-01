import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/data/services/suggestion_merger.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

FrameSuggestion _s(
  int frame,
  String name, {
  String? brand,
  String? model,
  double confidence = 0.8,
}) => FrameSuggestion(
  frameIndex: frame,
  result: AnalysisResult(
    itemName: name,
    brand: brand,
    model: model,
    description: '',
    category: 'Other',
    confidence: confidence,
  ),
);

void main() {
  const merger = SuggestionMerger();

  group('SuggestionMerger', () {
    test('merges the same item seen in two frames by normalized name', () {
      final merged = merger.merge([
        _s(0, 'Sony  TV', confidence: 0.6),
        _s(3, 'sony tv', confidence: 0.9),
      ]);

      expect(merged, hasLength(1));
      expect(merged.single.result.confidence, 0.9);
      expect(merged.single.frameIndex, 3);
    });

    test('merges by brand+model even when the names differ', () {
      final merged = merger.merge([
        _s(0, 'Television', brand: 'Sony', model: 'X90L', confidence: 0.7),
        _s(5, '55-inch smart TV', brand: 'sony', model: 'x90l',
            confidence: 0.85),
      ]);

      expect(merged, hasLength(1));
      expect(merged.single.result.itemName, '55-inch smart TV');
      expect(merged.single.frameIndex, 5);
    });

    test('brand alone is not identity — both brand and model must match', () {
      final merged = merger.merge([
        _s(0, 'Cordless drill', brand: 'Bosch', model: 'GSB 18V'),
        _s(1, 'Jigsaw', brand: 'Bosch', model: 'PST 700'),
      ]);

      expect(merged, hasLength(2));
    });

    test('keeps the first-seen copy on a confidence tie', () {
      final merged = merger.merge([
        _s(0, 'Lamp', confidence: 0.8),
        _s(4, 'Lamp', confidence: 0.8),
      ]);

      expect(merged, hasLength(1));
      expect(merged.single.frameIndex, 0);
    });

    test('preserves first-seen order of distinct items', () {
      final merged = merger.merge([
        _s(0, 'Couch'),
        _s(1, 'Bookshelf'),
        _s(1, 'couch', confidence: 0.95),
        _s(2, 'Piano'),
      ]);

      expect(merged.map((m) => m.result.itemName.toLowerCase()).toList(), [
        'couch',
        'bookshelf',
        'piano',
      ]);
    });

    test('suggestions without a usable name or brand+model never merge', () {
      final merged = merger.merge([
        _s(0, ''),
        _s(1, '  '),
      ]);

      expect(merged, hasLength(2));
    });

    test('empty input merges to empty output', () {
      expect(merger.merge(const []), isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/store_integration/domain/entities/product_match.dart';

void main() {
  group('ProductMatch', () {
    test('displayName includes brand when present', () {
      const match = ProductMatch(
        source: 'amazon',
        productName: '55" QLED TV',
        brand: 'Samsung',
      );
      expect(match.displayName, 'Samsung 55" QLED TV');
    });

    test('displayName falls back to productName when no brand', () {
      const match = ProductMatch(
        source: 'upc_itemdb',
        productName: 'Generic Widget',
      );
      expect(match.displayName, 'Generic Widget');
    });

    test('displayName falls back when brand is empty string', () {
      const match = ProductMatch(
        source: 'manual',
        productName: 'Widget',
        brand: '',
      );
      expect(match.displayName, 'Widget');
    });

    test('default matchConfidence is 0', () {
      const match = ProductMatch(source: 'upc_itemdb', productName: 'Test');
      expect(match.matchConfidence, 0.0);
    });

    test('copyWith creates updated copy preserving other fields', () {
      const original = ProductMatch(
        source: 'amazon',
        productName: 'TV',
        brand: 'LG',
        currentPrice: 799.99,
        matchConfidence: 0.95,
      );

      final updated = original.copyWith(currentPrice: 699.99, usedPrice: 450.0);

      expect(updated.source, 'amazon');
      expect(updated.productName, 'TV');
      expect(updated.brand, 'LG');
      expect(updated.currentPrice, 699.99);
      expect(updated.usedPrice, 450.0);
      expect(updated.matchConfidence, 0.95);
    });

    test('equality based on all props', () {
      const a = ProductMatch(
        source: 'amazon',
        productName: 'TV',
        currentPrice: 500.0,
      );
      const b = ProductMatch(
        source: 'amazon',
        productName: 'TV',
        currentPrice: 500.0,
      );
      const c = ProductMatch(
        source: 'amazon',
        productName: 'TV',
        currentPrice: 600.0,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}

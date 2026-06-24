import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';

Item _base() => Item(
  id: 'i1',
  name: 'Coffee',
  description: '',
  categoryId: 'c1',
  roomId: 'r1',
  isInsured: false,
  createdAt: DateTime(2026),
  modifiedAt: DateTime(2026),
);

void main() {
  group('Item.isLowStock', () {
    test('false when quantity is null', () {
      expect(_base().isLowStock, false);
    });
    test('false when lowStockThreshold is null', () {
      expect(_base().copyWith(quantity: () => 3.0).isLowStock, false);
    });
    test('true when quantity < threshold', () {
      final item = _base().copyWith(
        quantity: () => 2.0,
        lowStockThreshold: () => 5.0,
      );
      expect(item.isLowStock, true);
    });
    test('true when quantity == threshold', () {
      final item = _base().copyWith(
        quantity: () => 5.0,
        lowStockThreshold: () => 5.0,
      );
      expect(item.isLowStock, true);
    });
    test('false when quantity > threshold', () {
      final item = _base().copyWith(
        quantity: () => 6.0,
        lowStockThreshold: () => 5.0,
      );
      expect(item.isLowStock, false);
    });
  });

  group('Item.isConsumable', () {
    test('false when quantity is null', () {
      expect(_base().isConsumable, false);
    });
    test('true when quantity is set (even zero)', () {
      expect(_base().copyWith(quantity: () => 0.0).isConsumable, true);
    });
  });

  group('Item.copyWith quantity fields', () {
    test('sets quantity', () {
      expect(_base().copyWith(quantity: () => 10.0).quantity, 10.0);
    });
    test('clears quantity with null lambda', () {
      final item = _base()
          .copyWith(quantity: () => 5.0)
          .copyWith(quantity: () => null);
      expect(item.quantity, isNull);
    });
    test('sets quantityUnit', () {
      expect(_base().copyWith(quantityUnit: () => 'bags').quantityUnit, 'bags');
    });
    test('sets lowStockThreshold', () {
      expect(
        _base().copyWith(lowStockThreshold: () => 3.0).lowStockThreshold,
        3.0,
      );
    });
    test('quantity fields affect equality (in props)', () {
      final a = _base().copyWith(quantity: () => 5.0);
      final b = _base().copyWith(quantity: () => 5.0);
      expect(a, b);
      final c = _base().copyWith(quantity: () => 6.0);
      expect(a, isNot(c));
    });
  });
}

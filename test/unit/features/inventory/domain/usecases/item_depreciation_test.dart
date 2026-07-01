import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';

void main() {
  group('Item.calculateDepreciatedValueCents', () {
    test('returns null when purchasePriceCents is null', () {
      final result = Item.calculateDepreciatedValueCents(
        purchasePriceCents: null,
        purchaseDate: DateTime(2020, 1, 1),
        usefulLifeYears: 5,
      );
      expect(result, isNull);
    });

    test('returns null when purchaseDate is null', () {
      final result = Item.calculateDepreciatedValueCents(
        purchasePriceCents: 100000,
        purchaseDate: null,
        usefulLifeYears: 5,
      );
      expect(result, isNull);
    });

    test('returns purchasePriceCents when item is brand new (age <= 0)', () {
      final now = DateTime.now();
      final result = Item.calculateDepreciatedValueCents(
        purchasePriceCents: 100000,
        purchaseDate: now,
        usefulLifeYears: 5,
        asOf: now,
      );
      expect(result, 100000);
    });

    test('returns 10% residual value when item exceeds useful life', () {
      final result = Item.calculateDepreciatedValueCents(
        purchasePriceCents: 100000,
        purchaseDate: DateTime(2010, 1, 1),
        usefulLifeYears: 5,
        asOf: DateTime(2020, 1, 1),
      );
      expect(result, 10000); // 10% residual
    });

    test('depreciates linearly over useful life', () {
      // 5 year useful life, 2.5 years old → should be at midpoint
      final result = Item.calculateDepreciatedValueCents(
        purchasePriceCents: 100000,
        purchaseDate: DateTime(2020, 1, 1),
        usefulLifeYears: 5,
        asOf: DateTime(2022, 7, 2), // ~2.5 years later
      );
      // Depreciable amount = 1000 - 100 = 900
      // Depreciation per year = 900/5 = 180
      // After 2.5 years: 1000 - (180 * 2.5) = 1000 - 450 = 550
      expect(result, closeTo(55000, 500));
    });

    test('depreciates to residual at end of useful life', () {
      final result = Item.calculateDepreciatedValueCents(
        purchasePriceCents: 50000,
        purchaseDate: DateTime(2020, 1, 1),
        usefulLifeYears: 10,
        asOf: DateTime(2030, 1, 1),
      );
      expect(result, closeTo(5000, 100)); // 10% of 50000
    });

    test('works with different useful life durations', () {
      // 15 year useful life for furniture, 5 years old
      final result = Item.calculateDepreciatedValueCents(
        purchasePriceCents: 300000,
        purchaseDate: DateTime(2020, 1, 1),
        usefulLifeYears: 15,
        asOf: DateTime(2025, 1, 1),
      );
      // Depreciable: 3000 - 300 = 2700
      // Per year: 2700/15 = 180
      // After 5 years: 3000 - 900 = 2100
      expect(result, closeTo(210000, 500));
    });
  });

  group('ItemCondition', () {
    test('fromString returns correct condition', () {
      expect(ItemCondition.fromString('New'), ItemCondition.newItem);
      expect(ItemCondition.fromString('Like New'), ItemCondition.likeNew);
      expect(ItemCondition.fromString('Good'), ItemCondition.good);
      expect(ItemCondition.fromString('Fair'), ItemCondition.fair);
      expect(ItemCondition.fromString('Poor'), ItemCondition.poor);
    });

    test('fromString returns null for unknown value', () {
      expect(ItemCondition.fromString('Unknown'), isNull);
      expect(ItemCondition.fromString(null), isNull);
    });

    test('label returns human-readable string', () {
      expect(ItemCondition.newItem.label, 'New');
      expect(ItemCondition.likeNew.label, 'Like New');
      expect(ItemCondition.good.label, 'Good');
    });
  });

  group('Item entity', () {
    test('equality based on props', () {
      final now = DateTime(2024, 1, 1);
      final item1 = Item(
        id: '1',
        name: 'Test',
        description: 'Desc',
        categoryId: 'cat1',
        roomId: 'room1',
        createdAt: now,
        modifiedAt: now,
      );
      final item2 = Item(
        id: '1',
        name: 'Test',
        description: 'Desc',
        categoryId: 'cat1',
        roomId: 'room1',
        createdAt: now,
        modifiedAt: now,
      );
      expect(item1, equals(item2));
    });

    test('copyWith creates a new item with updated fields', () {
      final now = DateTime(2024, 1, 1);
      final item = Item(
        id: '1',
        name: 'Original',
        description: 'Desc',
        categoryId: 'cat1',
        roomId: 'room1',
        purchasePriceCents: 10000,
        createdAt: now,
        modifiedAt: now,
      );

      final updated = item.copyWith(
        name: 'Updated',
        purchasePriceCents: () => 20000,
      );

      expect(updated.name, 'Updated');
      expect(updated.purchasePriceCents, 20000);
      expect(updated.id, '1');
      expect(updated.description, 'Desc');
    });

    test('copyWith can set nullable fields to null', () {
      final now = DateTime(2024, 1, 1);
      final item = Item(
        id: '1',
        name: 'Test',
        description: 'Desc',
        categoryId: 'cat1',
        roomId: 'room1',
        purchasePriceCents: 10000,
        notes: 'Some notes',
        createdAt: now,
        modifiedAt: now,
      );

      final cleared = item.copyWith(
        purchasePriceCents: () => null,
        notes: () => null,
      );

      expect(cleared.purchasePriceCents, isNull);
      expect(cleared.notes, isNull);
    });
  });
}

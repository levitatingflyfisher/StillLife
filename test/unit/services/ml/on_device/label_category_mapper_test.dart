import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/on_device/label_category_mapper.dart';

void main() {
  group('categoryForMlKitLabel', () {
    test('maps common household labels into each StillLife category', () {
      expect(categoryForMlKitLabel('Laptop'), 'Electronics');
      expect(categoryForMlKitLabel('Television'), 'Electronics');
      expect(categoryForMlKitLabel('Chair'), 'Furniture');
      expect(categoryForMlKitLabel('Couch'), 'Furniture');
      expect(categoryForMlKitLabel('Refrigerator'), 'Appliance');
      expect(categoryForMlKitLabel('Oven'), 'Appliance');
      expect(categoryForMlKitLabel('Jeans'), 'Clothing');
      expect(categoryForMlKitLabel('Shoe'), 'Clothing');
      expect(categoryForMlKitLabel('Mug'), 'Kitchenware');
      expect(categoryForMlKitLabel('Cookware'), 'Kitchenware');
      expect(categoryForMlKitLabel('Vase'), 'Decor');
      expect(categoryForMlKitLabel('Candle'), 'Decor');
      expect(categoryForMlKitLabel('Drill'), 'Tool');
      expect(categoryForMlKitLabel('Hammer'), 'Tool');
      expect(categoryForMlKitLabel('Book'), 'Book');
      expect(categoryForMlKitLabel('Doll'), 'Toy');
      expect(categoryForMlKitLabel('Bicycle'), 'Sporting Goods');
      expect(categoryForMlKitLabel('Necklace'), 'Jewelry');
      expect(categoryForMlKitLabel('Painting'), 'Art');
      expect(categoryForMlKitLabel('Guitar'), 'Musical Instrument');
      expect(categoryForMlKitLabel('Piano'), 'Musical Instrument');
    });

    test('is case-insensitive — ML Kit casing must not matter', () {
      expect(categoryForMlKitLabel('laptop'), 'Electronics');
      expect(categoryForMlKitLabel('GUITAR'), 'Musical Instrument');
    });

    test('unknown labels fall to Other, never a guess', () {
      expect(categoryForMlKitLabel('Sky'), 'Other');
      expect(categoryForMlKitLabel('Fun'), 'Other');
      expect(categoryForMlKitLabel(''), 'Other');
    });

    test('every mapped value is a real StillLife category', () {
      const valid = {
        'Electronics',
        'Furniture',
        'Appliance',
        'Clothing',
        'Kitchenware',
        'Decor',
        'Tool',
        'Book',
        'Toy',
        'Sporting Goods',
        'Jewelry',
        'Art',
        'Musical Instrument',
        'Other',
      };
      for (final category in kMlKitLabelCategories.values.toSet()) {
        expect(valid, contains(category));
      }
    });
  });
}

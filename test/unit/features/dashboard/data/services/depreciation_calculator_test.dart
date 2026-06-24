import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/dashboard/data/services/depreciation_calculator.dart';

void main() {
  late DepreciationCalculator calculator;

  setUp(() {
    calculator = DepreciationCalculator();
  });

  group('DepreciationCalculator', () {
    group('useful life by category', () {
      test('Electronics has 5-year useful life', () {
        expect(calculator.getUsefulLife('Electronics'), 5);
      });

      test('Computers has 4-year useful life', () {
        expect(calculator.getUsefulLife('Computers'), 4);
      });

      test('Furniture has 10-year useful life', () {
        expect(calculator.getUsefulLife('Furniture'), 10);
      });

      test('Appliances has 10-year useful life', () {
        expect(calculator.getUsefulLife('Appliances'), 10);
      });

      test('Clothing has 3-year useful life', () {
        expect(calculator.getUsefulLife('Clothing'), 3);
      });

      test('Jewelry has 10-year useful life', () {
        expect(calculator.getUsefulLife('Jewelry'), 10);
      });

      test('Tools has 7-year useful life', () {
        expect(calculator.getUsefulLife('Tools'), 7);
      });

      test('Musical Instruments has 7-year useful life', () {
        expect(calculator.getUsefulLife('Musical Instruments'), 7);
      });

      test('Sporting Goods has 5-year useful life', () {
        expect(calculator.getUsefulLife('Sporting Goods'), 5);
      });

      test('Kitchenware has 7-year useful life', () {
        expect(calculator.getUsefulLife('Kitchenware'), 7);
      });

      test('Books has 5-year useful life', () {
        expect(calculator.getUsefulLife('Books'), 5);
      });
    });

    test('unknown category uses default 7-year useful life', () {
      expect(calculator.getUsefulLife('Random Stuff'), 7);
      expect(calculator.getUsefulLife('Other'), 7);
    });

    test('category name is case-insensitive', () {
      expect(calculator.getUsefulLife('electronics'), 5);
      expect(calculator.getUsefulLife('ELECTRONICS'), 5);
      expect(calculator.getUsefulLife('Electronics'), 5);
      expect(calculator.getUsefulLife('musical instruments'), 7);
      expect(calculator.getUsefulLife('MUSICAL INSTRUMENTS'), 7);
    });

    test('brand new item has zero depreciation', () {
      final purchaseDate = DateTime(2025, 6, 15);
      final info = calculator.calculateDepreciation(
        1000.0,
        purchaseDate,
        'Electronics',
        asOf: purchaseDate,
      );

      expect(info.originalValue, 1000.0);
      expect(info.currentValue, 1000.0);
      expect(info.totalDepreciation, 0.0);
      expect(info.ageYears, 0.0);
      expect(info.usefulLife, 5);
      expect(info.percentRemaining, 100.0);
    });

    test('fully depreciated item retains 10% residual value', () {
      final purchaseDate = DateTime(2010, 1, 1);
      final asOf = DateTime(2025, 6, 15); // 15+ years later

      final info = calculator.calculateDepreciation(
        1000.0,
        purchaseDate,
        'Electronics', // 5-year life
        asOf: asOf,
      );

      expect(info.originalValue, 1000.0);
      expect(info.currentValue, 100.0); // 10% residual
      expect(info.totalDepreciation, 900.0);
      expect(info.percentRemaining, 10.0);
    });

    test('mid-life item has proportional depreciation', () {
      final purchaseDate = DateTime(2023, 6, 15);
      // Exactly 2 years later for a 4-year useful life (Computers)
      final asOf = DateTime(2025, 6, 15);

      final info = calculator.calculateDepreciation(
        2000.0,
        purchaseDate,
        'Computers',
        asOf: asOf,
      );

      expect(info.originalValue, 2000.0);
      expect(info.usefulLife, 4);

      // Depreciable amount = 2000 - 200 (10%) = 1800
      // Annual depreciation = 1800 / 4 = 450
      // ~2 years of depreciation = ~900
      const expectedAnnualDep = 1800.0 / 4.0;
      expect(info.annualDepreciation, closeTo(expectedAnnualDep, 0.01));
      expect(info.ageYears, closeTo(2.0, 0.01));
      expect(info.currentValue, closeTo(2000.0 - 900.0, 5.0));
    });

    test(
      'calculateCurrentValue returns same as calculateDepreciation.currentValue',
      () {
        final purchaseDate = DateTime(2022, 1, 1);
        final asOf = DateTime(2025, 1, 1);

        final currentValue = calculator.calculateCurrentValue(
          500.0,
          purchaseDate,
          'Furniture',
          asOf: asOf,
        );
        final info = calculator.calculateDepreciation(
          500.0,
          purchaseDate,
          'Furniture',
          asOf: asOf,
        );

        expect(currentValue, info.currentValue);
      },
    );

    test('item purchased in the future has no depreciation', () {
      final purchaseDate = DateTime(2030, 1, 1);
      final asOf = DateTime(2025, 6, 15);

      final info = calculator.calculateDepreciation(
        1000.0,
        purchaseDate,
        'Tools',
        asOf: asOf,
      );

      expect(info.totalDepreciation, 0.0);
      expect(info.currentValue, 1000.0);
    });
  });
}

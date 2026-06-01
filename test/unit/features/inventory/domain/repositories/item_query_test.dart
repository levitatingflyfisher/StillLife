import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/widgets/filter_dialog.dart';

void main() {
  group('FilterResult.applyTo', () {
    test('passes hasPhoto through to ItemQuery', () {
      const filter = FilterResult(hasPhoto: true);
      final q = filter.applyTo(const ItemQuery());
      expect(q.hasPhoto, isTrue);
    });

    test('passes hasReceipt through to ItemQuery', () {
      const filter = FilterResult(hasReceipt: true);
      final q = filter.applyTo(const ItemQuery());
      expect(q.hasReceipt, isTrue);
    });

    test('passes hasBarcode through to ItemQuery', () {
      const filter = FilterResult(hasBarcode: true);
      final q = filter.applyTo(const ItemQuery());
      expect(q.hasBarcode, isTrue);
    });

    test('passes addedAfter/addedBefore through', () {
      final after = DateTime(2025, 1, 1);
      final before = DateTime(2025, 12, 31);
      final filter = FilterResult(addedAfter: after, addedBefore: before);
      final q = filter.applyTo(const ItemQuery());
      expect(q.addedAfter, equals(after));
      expect(q.addedBefore, equals(before));
    });

    test('isActive is true when hasPhoto set', () {
      expect(const FilterResult(hasPhoto: true).isActive, isTrue);
    });

    test('activeFilterCount counts presence flags', () {
      const f = FilterResult(hasPhoto: true, hasReceipt: true);
      expect(f.activeFilterCount, equals(2));
    });

    test('activeFilterCount counts hasBarcode', () {
      const f = FilterResult(hasBarcode: true);
      expect(f.activeFilterCount, equals(1));
    });

    test('isActive is false when all fields null', () {
      expect(const FilterResult().isActive, isFalse);
    });
  });
}

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  // Single setUp: initialise DB and seed required FK rows.
  setUp(() async {
    database = db_pkg.AppDatabase.memory();
    await database
        .into(database.properties)
        .insert(
          db_pkg.PropertiesCompanion.insert(
            id: 'p1',
            name: 'Home',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
    await database
        .into(database.rooms)
        .insert(
          db_pkg.RoomsCompanion.insert(
            id: 'room-1',
            name: 'Kitchen',
            propertyId: 'p1',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
    await database
        .into(database.categories)
        .insert(
          db_pkg.CategoriesCompanion.insert(
            id: 'cat-1',
            name: 'Food',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
  });
  tearDown(() async => database.close());

  Future<void> seedItem({
    String id = 'item-1',
    String name = 'Coffee',
    double? quantity,
    String? quantityUnit,
    double? lowStockThreshold,
  }) async {
    await database.itemDao.insertItem(
      db_pkg.ItemsCompanion.insert(
        id: id,
        name: name,
        categoryId: 'cat-1',
        roomId: 'room-1',
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026),
        quantity: Value(quantity),
        quantityUnit: Value(quantityUnit),
        lowStockThreshold: Value(lowStockThreshold),
      ),
    );
  }

  group('watchLowStockItems', () {
    test('returns items where quantity <= threshold', () async {
      await seedItem(id: 'i1', quantity: 2.0, lowStockThreshold: 5.0);
      await seedItem(id: 'i2', quantity: 6.0, lowStockThreshold: 5.0);
      await seedItem(id: 'i3'); // no quantity — excluded

      final rows = await database.itemDao.watchLowStockItems().first;
      final ids = rows.map((r) => r.id).toList();
      expect(ids, contains('i1'));
      expect(ids, isNot(contains('i2')));
      expect(ids, isNot(contains('i3')));
    });

    test('includes item at exactly the threshold', () async {
      await seedItem(id: 'i1', quantity: 5.0, lowStockThreshold: 5.0);
      final rows = await database.itemDao.watchLowStockItems().first;
      expect(rows.map((r) => r.id), contains('i1'));
    });

    test('excludes soft-deleted items', () async {
      await seedItem(id: 'i1', quantity: 1.0, lowStockThreshold: 5.0);
      await database.itemDao.deleteItem('i1');
      final rows = await database.itemDao.watchLowStockItems().first;
      expect(rows, isEmpty);
    });
  });

  group('decrementQuantity', () {
    test('reduces quantity by 1', () async {
      await seedItem(id: 'i1', quantity: 10.0);
      await database.itemDao.decrementQuantity('i1');
      final row = await database.itemDao.getItemById('i1');
      expect(row?.quantity, 9.0);
    });

    test('clamps at 0 (does not go negative)', () async {
      await seedItem(id: 'i1', quantity: 0.0);
      await database.itemDao.decrementQuantity('i1');
      final row = await database.itemDao.getItemById('i1');
      expect(row?.quantity, 0.0);
    });

    test('does nothing when quantity is null', () async {
      await seedItem(id: 'i1'); // quantity = null
      await database.itemDao.decrementQuantity('i1');
      final row = await database.itemDao.getItemById('i1');
      expect(row?.quantity, isNull);
    });

    test('two sequential decrements both apply (transactional)', () async {
      await seedItem(id: 'i1', quantity: 5.0);
      // Drive both decrements concurrently. A non-transactional implementation
      // can read 5 → 5 → write 4 → write 4 (final = 4). Wrapped in a
      // transaction with a re-read, the writes serialise to 5 → 4 → 3.
      await Future.wait([
        database.itemDao.decrementQuantity('i1'),
        database.itemDao.decrementQuantity('i1'),
      ]);
      final row = await database.itemDao.getItemById('i1');
      expect(row?.quantity, 3.0);
    });

    test('updates modifiedAt', () async {
      await seedItem(id: 'i1', quantity: 5.0);
      final item1 = await database.itemDao.getItemById('i1');
      await Future.delayed(const Duration(milliseconds: 10));
      await database.itemDao.decrementQuantity('i1');
      final item2 = await database.itemDao.getItemById('i1');
      expect(item2?.modifiedAt.isAfter(item1!.modifiedAt), true);
    });
  });
}

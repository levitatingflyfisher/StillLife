import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/data/repositories/item_repository_impl.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;
import 'package:still_life/services/storage/photo_storage_service.dart';

import '../../../../../test_setup.dart';

class _FakePhotoStorage extends Fake implements PhotoStorageService {}

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  late ItemRepositoryImpl repo;

  setUp(() {
    database = db_pkg.AppDatabase.memory();
    repo = ItemRepositoryImpl(database, _FakePhotoStorage());
  });
  tearDown(() async => database.close());

  Future<void> seedDeps() async {
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
            id: 'r1',
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
            id: 'c1',
            name: 'Food',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
  }

  test('_mapToEntity includes quantity fields', () async {
    await seedDeps();
    await database.itemDao.insertItem(
      db_pkg.ItemsCompanion.insert(
        id: 'item-1',
        name: 'Coffee',
        categoryId: 'c1',
        roomId: 'r1',
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026),
        quantity: const Value(10.0),
        quantityUnit: const Value('bags'),
        lowStockThreshold: const Value(3.0),
      ),
    );
    final result = await repo.getItem('item-1');
    result.when(
      success: (item) {
        expect(item.quantity, 10.0);
        expect(item.quantityUnit, 'bags');
        expect(item.lowStockThreshold, 3.0);
        expect(item.isConsumable, true);
      },
      failure: (f) => fail('Expected success, got $f'),
    );
  });

  test('createItem round-trips quantity fields', () async {
    await seedDeps();
    final item = Item(
      id: 'new-1',
      name: 'Salt',
      description: '',
      categoryId: 'c1',
      roomId: 'r1',
      isInsured: false,
      createdAt: DateTime(2026),
      modifiedAt: DateTime(2026),
      quantity: 5.0,
      quantityUnit: 'tins',
      lowStockThreshold: 1.0,
    );
    final result = await repo.createItem(item);
    result.when(
      success: (saved) {
        expect(saved.quantity, 5.0);
        expect(saved.quantityUnit, 'tins');
        expect(saved.lowStockThreshold, 1.0);
      },
      failure: (f) => fail('Expected success, got $f'),
    );
  });

  test('decrementQuantity reduces quantity and returns updated item', () async {
    await seedDeps();
    await database.itemDao.insertItem(
      db_pkg.ItemsCompanion.insert(
        id: 'item-1',
        name: 'Coffee',
        categoryId: 'c1',
        roomId: 'r1',
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026),
        quantity: const Value(10.0),
        lowStockThreshold: const Value(3.0),
      ),
    );
    final result = await repo.decrementQuantity('item-1');
    result.when(
      success: (item) => expect(item.quantity, 9.0),
      failure: (f) => fail('Expected success, got $f'),
    );
  });

  test('watchLowStockItems streams items below threshold', () async {
    await seedDeps();
    await database.itemDao.insertItem(
      db_pkg.ItemsCompanion.insert(
        id: 'item-1',
        name: 'Coffee',
        categoryId: 'c1',
        roomId: 'r1',
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026),
        quantity: const Value(2.0),
        lowStockThreshold: const Value(3.0),
      ),
    );
    final lowStock = await repo.watchLowStockItems().first;
    expect(lowStock.map((i) => i.id), contains('item-1'));
    expect(lowStock.first.isLowStock, true);
  });
}

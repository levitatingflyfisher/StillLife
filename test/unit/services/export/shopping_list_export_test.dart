import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;
import 'package:still_life/services/export/csv_export_service.dart';

import '../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  late CsvExportService service;

  setUp(() {
    database = db_pkg.AppDatabase.memory();
    service = CsvExportService(database);
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
            name: 'Consumables',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
  }

  Future<void> seedItem({
    required String id,
    required String name,
    double? quantity,
    String? unit,
    double? threshold,
  }) async {
    await database.itemDao.insertItem(
      db_pkg.ItemsCompanion.insert(
        id: id,
        name: name,
        categoryId: 'c1',
        roomId: 'r1',
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026),
        quantity: Value(quantity),
        quantityUnit: Value(unit),
        lowStockThreshold: Value(threshold),
      ),
    );
  }

  test(
    'exportItemsToCsv includes Quantity, Unit, Low Stock Threshold headers',
    () async {
      await seedDeps();
      await seedItem(
        id: 'i1',
        name: 'Coffee',
        quantity: 5.0,
        unit: 'bags',
        threshold: 2.0,
      );
      final csv = await service.exportItemsToCsv();
      expect(csv, contains('"Quantity"'));
      expect(csv, contains('"Unit"'));
      expect(csv, contains('"Low Stock Threshold"'));
    },
  );

  test('exportItemsToCsv includes quantity values in rows', () async {
    await seedDeps();
    await seedItem(
      id: 'i1',
      name: 'Coffee',
      quantity: 5.0,
      unit: 'bags',
      threshold: 2.0,
    );
    final csv = await service.exportItemsToCsv();
    expect(csv, contains('"5.0"'));
    expect(csv, contains('"bags"'));
    expect(csv, contains('"2.0"'));
  });

  test('exportShoppingListToCsv has expected headers', () async {
    await seedDeps();
    final csv = await service.exportShoppingListToCsv();
    expect(csv, contains('"Name"'));
    expect(csv, contains('"Category"'));
    expect(csv, contains('"Quantity"'));
    expect(csv, contains('"Low Stock Threshold"'));
  });

  test('exportShoppingListToCsv only includes low-stock items', () async {
    await seedDeps();
    await seedItem(id: 'i1', name: 'Coffee', quantity: 1.0, threshold: 5.0);
    await seedItem(id: 'i2', name: 'Bread', quantity: 10.0, threshold: 5.0);
    final csv = await service.exportShoppingListToCsv();
    expect(csv, contains('Coffee'));
    expect(csv, isNot(contains('Bread')));
  });

  test('exportShoppingListToCsv excludes items with no threshold', () async {
    await seedDeps();
    await seedItem(id: 'i1', name: 'Coffee', quantity: 1.0); // no threshold
    final csv = await service.exportShoppingListToCsv();
    final lines = csv.trim().split('\n');
    expect(lines.length, 1); // header only
  });
}

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;

  setUp(() async {
    database = db_pkg.AppDatabase.memory();
    final now = DateTime.now();
    await database
        .into(database.properties)
        .insert(
          db_pkg.PropertiesCompanion.insert(
            id: 'prop-1',
            name: 'Test Property',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await database
        .into(database.rooms)
        .insert(
          db_pkg.RoomsCompanion.insert(
            id: 'room-1',
            propertyId: 'prop-1',
            name: 'Test Room',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await database
        .into(database.categories)
        .insert(
          db_pkg.CategoriesCompanion.insert(
            id: 'cat-1',
            name: 'Test Cat',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() => database.close());

  // Helper: insert an item. Returns itemId.
  Future<String> insertItem(String name, {String? barcode}) async {
    final id = 'item-${name.toLowerCase().replaceAll(' ', '-')}';
    await database.itemDao.insertItem(
      db_pkg.ItemsCompanion.insert(
        id: id,
        name: name,
        categoryId: 'cat-1',
        roomId: 'room-1',
        barcode: Value(barcode),
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ),
    );
    return id;
  }

  group('ItemDao presence filters', () {
    test('hasPhoto=true returns only items with non-deleted photos', () async {
      final idWith = await insertItem('With Photo');
      await insertItem('No Photo');

      await database
          .into(database.photos)
          .insert(
            db_pkg.PhotosCompanion.insert(
              id: 'photo-1',
              itemId: idWith,
              filePath: '/p.jpg',
              capturedAt: DateTime.now(),
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
            ),
          );

      final results = await database.itemDao
          .watchAllItems(hasPhoto: true)
          .first;
      expect(results.map((r) => r.name), contains('With Photo'));
      expect(results.map((r) => r.name), isNot(contains('No Photo')));
    });

    test('hasBarcode=true excludes null and empty barcodes', () async {
      await insertItem('Barcoded', barcode: '012345678905');
      await insertItem('No Barcode');
      await insertItem('Empty Barcode', barcode: '');

      final results = await database.itemDao
          .watchAllItems(hasBarcode: true)
          .first;
      expect(results.map((r) => r.name), contains('Barcoded'));
      expect(results.map((r) => r.name), isNot(contains('No Barcode')));
      expect(results.map((r) => r.name), isNot(contains('Empty Barcode')));
    });

    test('hasReceipt=true returns only items with receipts', () async {
      final idWith = await insertItem('With Receipt');
      await insertItem('No Receipt');

      await database
          .into(database.receipts)
          .insert(
            db_pkg.ReceiptsCompanion.insert(
              id: 'rcpt-1',
              itemId: Value(idWith),
              photoPath: '/r.jpg',
              createdAt: DateTime.now(),
            ),
          );

      final results = await database.itemDao
          .watchAllItems(hasReceipt: true)
          .first;
      expect(results.map((r) => r.name), contains('With Receipt'));
      expect(results.map((r) => r.name), isNot(contains('No Receipt')));
    });
  });
}

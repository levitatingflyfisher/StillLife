import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart';

import '../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase', () {
    test('creates in-memory database successfully', () {
      expect(db, isNotNull);
      expect(db.schemaVersion, 11);
    });

    test('creates all tables', () async {
      // Insert into each table to verify they exist
      final now = DateTime.now();

      // Properties
      await db
          .into(db.properties)
          .insert(
            PropertiesCompanion.insert(
              id: 'p1',
              name: 'Home',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      final properties = await db.select(db.properties).get();
      expect(properties, hasLength(1));
      expect(properties.first.name, 'Home');

      // Rooms
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'r1',
              propertyId: 'p1',
              name: 'Living Room',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      final rooms = await db.select(db.rooms).get();
      expect(rooms, hasLength(1));

      // Categories
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'c1',
              name: 'Electronics',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      final categories = await db.select(db.categories).get();
      expect(categories, hasLength(1));

      // Items
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'i1',
              name: 'TV',
              categoryId: 'c1',
              roomId: 'r1',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      final items = await db.select(db.items).get();
      expect(items, hasLength(1));
      expect(items.first.name, 'TV');

      // Tags
      await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              id: 't1',
              name: 'Valuable',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      final tags = await db.select(db.tags).get();
      expect(tags, hasLength(1));

      // ItemTags
      await db
          .into(db.itemTags)
          .insert(
            ItemTagsCompanion.insert(itemId: 'i1', tagId: 't1', createdAt: now),
          );
      final itemTags = await db.select(db.itemTags).get();
      expect(itemTags, hasLength(1));

      // Photos
      await db
          .into(db.photos)
          .insert(
            PhotosCompanion.insert(
              id: 'ph1',
              itemId: 'i1',
              filePath: '/path/to/photo.jpg',
              capturedAt: now,
              createdAt: now,
              modifiedAt: now,
            ),
          );
      final photos = await db.select(db.photos).get();
      expect(photos, hasLength(1));
    });

    test('CRDT columns have default empty values', () async {
      final now = DateTime.now();
      await db
          .into(db.properties)
          .insert(
            PropertiesCompanion.insert(
              id: 'p1',
              name: 'Test',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      final property = await (db.select(
        db.properties,
      )..where((t) => t.id.equals('p1'))).getSingle();
      expect(property.nodeId, '');
      expect(property.hlc, '');
    });

    test('foreign key constraints work', () async {
      final now = DateTime.now();

      // Create prerequisite data
      await db
          .into(db.properties)
          .insert(
            PropertiesCompanion.insert(
              id: 'p1',
              name: 'Home',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'r1',
              propertyId: 'p1',
              name: 'Room',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'c1',
              name: 'Cat',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      // Item with valid FKs should succeed
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'i1',
              name: 'Valid Item',
              categoryId: 'c1',
              roomId: 'r1',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      final items = await db.select(db.items).get();
      expect(items, hasLength(1));
    });
  });

  group('ItemDao', () {
    late String roomId;
    late String categoryId;

    setUp(() async {
      final now = DateTime.now();
      roomId = 'room1';
      categoryId = 'cat1';

      await db
          .into(db.properties)
          .insert(
            PropertiesCompanion.insert(
              id: 'p1',
              name: 'Home',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: roomId,
              propertyId: 'p1',
              name: 'Living Room',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: categoryId,
              name: 'Electronics',
              createdAt: now,
              modifiedAt: now,
            ),
          );
    });

    test('getTotalValue returns sum of currentValue', () async {
      final now = DateTime.now();
      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i1',
          name: 'TV',
          categoryId: categoryId,
          roomId: roomId,
          currentValue: const Value(500.0),
          createdAt: now,
          modifiedAt: now,
        ),
      );
      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i2',
          name: 'Speaker',
          categoryId: categoryId,
          roomId: roomId,
          currentValue: const Value(300.0),
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final total = await db.itemDao.getTotalValue();
      expect(total, 800.0);
    });

    test('getTotalValue filtered by room', () async {
      final now = DateTime.now();
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'room2',
              propertyId: 'p1',
              name: 'Bedroom',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i1',
          name: 'TV',
          categoryId: categoryId,
          roomId: roomId,
          currentValue: const Value(500.0),
          createdAt: now,
          modifiedAt: now,
        ),
      );
      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i2',
          name: 'Lamp',
          categoryId: categoryId,
          roomId: 'room2',
          currentValue: const Value(100.0),
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final total = await db.itemDao.getTotalValue(roomId: roomId);
      expect(total, 500.0);
    });

    test('getValueByCategory returns grouped totals', () async {
      final now = DateTime.now();
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat2',
              name: 'Furniture',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i1',
          name: 'TV',
          categoryId: categoryId,
          roomId: roomId,
          currentValue: const Value(500.0),
          createdAt: now,
          modifiedAt: now,
        ),
      );
      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i2',
          name: 'Sofa',
          categoryId: 'cat2',
          roomId: roomId,
          currentValue: const Value(800.0),
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final byCategory = await db.itemDao.getValueByCategory();
      expect(byCategory[categoryId], 500.0);
      expect(byCategory['cat2'], 800.0);
    });

    test('countItems returns correct count', () async {
      final now = DateTime.now();
      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i1',
          name: 'Item 1',
          categoryId: categoryId,
          roomId: roomId,
          createdAt: now,
          modifiedAt: now,
        ),
      );
      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i2',
          name: 'Item 2',
          categoryId: categoryId,
          roomId: roomId,
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final count = await db.itemDao.countItems();
      expect(count, 2);
    });

    test('searchItems finds items via FTS', () async {
      final now = DateTime.now();
      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i1',
          name: 'Samsung OLED TV',
          description: const Value('55 inch television'),
          categoryId: categoryId,
          roomId: roomId,
          createdAt: now,
          modifiedAt: now,
        ),
      );
      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'i2',
          name: 'Sony Headphones',
          description: const Value('Wireless noise cancelling'),
          categoryId: categoryId,
          roomId: roomId,
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final results = await db.itemDao.searchItems('Samsung').first;
      expect(results, hasLength(1));
      expect(results.first.name, 'Samsung OLED TV');

      final results2 = await db.itemDao.searchItems('wireless').first;
      expect(results2, hasLength(1));
      expect(results2.first.name, 'Sony Headphones');
    });

    test('schema v8 — items table has quantity columns', () async {
      final now = DateTime.now();
      await db
          .into(db.properties)
          .insert(
            PropertiesCompanion.insert(
              id: 'p-v8',
              name: 'Home',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'r-v8',
              name: 'Kitchen',
              propertyId: 'p-v8',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'c-v8',
              name: 'Food',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db.itemDao.insertItem(
        ItemsCompanion.insert(
          id: 'q-1',
          name: 'Coffee',
          categoryId: 'c-v8',
          roomId: 'r-v8',
          createdAt: now,
          modifiedAt: now,
          quantity: const Value(10.0),
          quantityUnit: const Value('bags'),
          lowStockThreshold: const Value(2.0),
        ),
      );
      final row = await db.itemDao.getItemById('q-1');
      expect(row?.quantity, 10.0);
      expect(row?.quantityUnit, 'bags');
      expect(row?.lowStockThreshold, 2.0);
    });
  });
}

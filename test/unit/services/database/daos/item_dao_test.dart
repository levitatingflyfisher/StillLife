import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    // Seed FK dependencies.
    final now = DateTime(2025, 1, 1);
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Electronics',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Home',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room1',
            propertyId: 'prop1',
            name: 'Living Room',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  ItemsCompanion item(String id, String name, {bool deleted = false}) {
    final now = DateTime(2025, 1, 1);
    return ItemsCompanion.insert(
      id: id,
      name: name,
      categoryId: 'cat1',
      roomId: 'room1',
      isDeleted: Value(deleted),
      createdAt: now,
      modifiedAt: now,
    );
  }

  group('ItemDao.watchAllItems', () {
    test('returns active items only', () async {
      await db.into(db.items).insert(item('i1', 'TV'));
      await db.into(db.items).insert(item('i2', 'Deleted', deleted: true));

      final result = await db.itemDao.watchAllItems().first;
      expect(result.length, 1);
      expect(result.first.name, 'TV');
    });

    test('filters by roomId', () async {
      final now = DateTime(2025, 1, 1);
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'room2',
              propertyId: 'prop1',
              name: 'Bedroom',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db.into(db.items).insert(item('i1', 'TV'));
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'i2',
              name: 'Lamp',
              categoryId: 'cat1',
              roomId: 'room2',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      final result = await db.itemDao.watchAllItems(roomId: 'room1').first;
      expect(result.length, 1);
      expect(result.first.name, 'TV');
    });

    test('filters by categoryId', () async {
      final now = DateTime(2025, 1, 1);
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
      await db.into(db.items).insert(item('i1', 'TV'));
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'i2',
              name: 'Chair',
              categoryId: 'cat2',
              roomId: 'room1',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      final result = await db.itemDao.watchAllItems(categoryId: 'cat2').first;
      expect(result.length, 1);
      expect(result.first.name, 'Chair');
    });
  });

  group('ItemDao.deleteItem (soft-delete)', () {
    test('marks item as deleted, not removed from DB', () async {
      await db.into(db.items).insert(item('i1', 'TV'));
      await db.itemDao.deleteItem('i1');

      // watchAllItems should hide it.
      final visible = await db.itemDao.watchAllItems().first;
      expect(visible, isEmpty);

      // But the row is still in DB with isDeleted=true.
      final raw = await (db.select(
        db.items,
      )..where((t) => t.id.equals('i1'))).getSingleOrNull();
      expect(raw, isNotNull);
      expect(raw!.isDeleted, isTrue);
    });

    test('soft-deletes associated photos', () async {
      final now = DateTime(2025, 1, 1);
      await db.into(db.items).insert(item('i1', 'TV'));
      await db
          .into(db.photos)
          .insert(
            PhotosCompanion.insert(
              id: 'p1',
              itemId: 'i1',
              filePath: '/photos/tv.jpg',
              capturedAt: now,
              createdAt: now,
              modifiedAt: now,
            ),
          );

      await db.itemDao.deleteItem('i1');

      final photo = await (db.select(
        db.photos,
      )..where((t) => t.id.equals('p1'))).getSingleOrNull();
      expect(photo?.isDeleted, isTrue);
    });

    test('soft-deletes associated appraisals', () async {
      final now = DateTime(2025, 1, 1);
      await db.into(db.items).insert(item('i1', 'TV'));
      final queriedAt = DateTime(2025, 1, 1).millisecondsSinceEpoch;
      final expiresAt = DateTime(2025, 12, 31).millisecondsSinceEpoch;
      await db
          .into(db.appraisals)
          .insert(
            AppraisalsCompanion.insert(
              id: 'a1',
              itemId: 'i1',
              mode: 'resale',
              value: 500.0,
              itemModelKey: 'tv|good',
              queriedAt: queriedAt,
              expiresAt: expiresAt,
            ),
          );

      await db.itemDao.deleteItem('i1');

      final appraisal = await (db.select(
        db.appraisals,
      )..where((t) => t.id.equals('a1'))).getSingleOrNull();
      expect(appraisal?.isDeleted, isTrue);
      // Confirm the helper now omits it from per-item view.
      final visible = await db.appraisalDao.watchForItem('i1').first;
      expect(visible, isEmpty);
      // Suppress unused: keep `now` local-scope explicit for FK seeding clarity.
      expect(now.year, 2025);
    });

    test('hard-deletes itemTag junction rows', () async {
      final now = DateTime(2025, 1, 1);
      await db.into(db.items).insert(item('i1', 'TV'));
      await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              id: 'tag1',
              name: 'Electronics',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.itemTags)
          .insert(
            ItemTagsCompanion.insert(
              itemId: 'i1',
              tagId: 'tag1',
              createdAt: now,
            ),
          );

      await db.itemDao.deleteItem('i1');

      final tags = await (db.select(
        db.itemTags,
      )..where((t) => t.itemId.equals('i1'))).get();
      expect(tags, isEmpty);
    });
  });

  group('ItemDao.getItemById', () {
    test('returns item when found', () async {
      await db.into(db.items).insert(item('i1', 'Couch'));
      final result = await db.itemDao.getItemById('i1');
      expect(result?.name, 'Couch');
    });

    test('returns null for unknown id', () async {
      final result = await db.itemDao.getItemById('nope');
      expect(result, isNull);
    });
  });

  group('ItemDao.moveItemsToRoom', () {
    test('changes roomId for multiple items', () async {
      final now = DateTime(2025, 1, 1);
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'room2',
              propertyId: 'prop1',
              name: 'Bedroom',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db.into(db.items).insert(item('i1', 'Lamp'));
      await db.into(db.items).insert(item('i2', 'Fan'));

      await db.itemDao.moveItemsToRoom(['i1', 'i2'], 'room2');

      final items = await db.itemDao.watchAllItems(roomId: 'room2').first;
      expect(items.length, 2);
    });
  });

  group('ItemDao.countItems', () {
    test('counts non-deleted items', () async {
      await db.into(db.items).insert(item('i1', 'A'));
      await db.into(db.items).insert(item('i2', 'B'));
      await db.into(db.items).insert(item('i3', 'C', deleted: true));

      final count = await db.itemDao.countItems();
      expect(count, 2);
    });
  });
}

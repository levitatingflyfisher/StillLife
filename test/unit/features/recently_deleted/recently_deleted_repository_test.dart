import 'package:crdt/crdt.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/features/inventory/data/repositories/item_repository_impl.dart';
import 'package:still_life/features/recently_deleted/data/recently_deleted_repository.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/storage/photo_storage_service.dart';
import 'package:still_life/services/sync/crdt_manager.dart';

import '../../../test_setup.dart';

class _MockPhotoStorage extends Mock implements PhotoStorageService {}

class _MockCrdt extends Mock implements CrdtManager {}

/// Delete is soft (the sync tombstone), so the way back already exists in
/// storage. These pin that Undo and Recently deleted really reverse it.
void main() {
  ensureSqlite3();

  late AppDatabase db;
  late _MockPhotoStorage photoStorage;
  late ItemRepositoryImpl items;
  late RecentlyDeletedRepository trash;
  final t0 = DateTime(2025, 1, 1);

  Future<void> seedItem(String id, String name) => db
      .into(db.items)
      .insert(
        ItemsCompanion.insert(
          id: id,
          name: name,
          categoryId: 'cat1',
          roomId: 'room1',
          createdAt: t0,
          modifiedAt: t0,
          hlc: const Value('0001'),
        ),
      );

  Future<void> seedPhoto(String id, String itemId) => db
      .into(db.photos)
      .insert(
        PhotosCompanion.insert(
          id: id,
          itemId: itemId,
          filePath: '/photos/$id.jpg',
          capturedAt: t0,
          createdAt: t0,
          modifiedAt: t0,
        ),
      );

  Future<Item> itemRow(String id) =>
      (db.select(db.items)..where((t) => t.id.equals(id))).getSingle();

  setUp(() async {
    db = AppDatabase.memory();
    photoStorage = _MockPhotoStorage();
    when(() => photoStorage.deletePhoto(any())).thenAnswer((_) async {});
    items = ItemRepositoryImpl(db, photoStorage);
    trash = RecentlyDeletedRepository(db);
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Electronics',
            createdAt: t0,
            modifiedAt: t0,
          ),
        );
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Home',
            createdAt: t0,
            modifiedAt: t0,
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room1',
            propertyId: 'prop1',
            name: 'Living Room',
            createdAt: t0,
            modifiedAt: t0,
          ),
        );
  });

  tearDown(() => db.close());

  test(
    'deleting an item keeps its photo files, so a restore has them',
    () async {
      await seedItem('i1', 'TV');
      await seedPhoto('p1', 'i1');

      await items.deleteItem('i1');

      verifyNever(() => photoStorage.deletePhoto(any()));
    },
  );

  test('restore brings the item, its photos and its tags back', () async {
    await seedItem('i1', 'TV');
    await seedPhoto('p1', 'i1');
    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(
            id: 't1',
            name: 'Gift',
            createdAt: t0,
            modifiedAt: t0,
          ),
        );
    await db.tagDao.setItemTags('i1', ['t1']);

    final deletion = await trash.snapshot(['i1']);
    await items.deleteItems(['i1']);
    expect((await itemRow('i1')).isDeleted, isTrue);

    await trash.restoreItems(deletion);

    expect((await itemRow('i1')).isDeleted, isFalse);
    final photo = await (db.select(
      db.photos,
    )..where((t) => t.id.equals('p1'))).getSingle();
    expect(photo.isDeleted, isFalse);
    expect(await db.tagDao.getItemTagIds('i1'), ['t1']);
  });

  test(
    'restore leaves a photo deleted on its own before stays deleted',
    () async {
      await seedItem('i1', 'TV');
      await seedPhoto('p1', 'i1');
      await seedPhoto('p-old', 'i1');
      await (db.update(db.photos)..where((t) => t.id.equals('p-old'))).write(
        PhotosCompanion(
          isDeleted: const Value(true),
          modifiedAt: Value(DateTime(2024, 6, 1)),
        ),
      );

      await items.deleteItem('i1');
      await trash.restoreItem('i1');

      final rows = await db.select(db.photos).get();
      final byId = {for (final r in rows) r.id: r.isDeleted};
      expect(byId, {'p1': false, 'p-old': true});
    },
  );

  test('Recently deleted lists deleted items newest first, then drops a '
      'restored one', () async {
    await seedItem('i1', 'TV');
    await seedItem('i2', 'Lamp');
    await seedItem('i3', 'Sofa');
    await items.deleteItem('i1');
    await items.deleteItem('i2');
    // Drift stores whole seconds; pin distinct delete times.
    for (final (id, at) in [
      ('i1', DateTime(2025, 2, 1)),
      ('i2', DateTime(2025, 3, 1)),
    ]) {
      await (db.update(db.items)..where((t) => t.id.equals(id))).write(
        ItemsCompanion(modifiedAt: Value(at)),
      );
    }

    final listed = await trash.watchDeletedItems().first;
    expect(listed.map((d) => d.name), ['Lamp', 'TV']);

    await trash.restoreItem('i2');
    final after = await trash.watchDeletedItems().first;
    expect(after.map((d) => d.name), ['TV']);
  });

  test(
    'a restore is stamped newer than the tombstone, so it wins LWW sync',
    () async {
      final crdt = _MockCrdt();
      when(crdt.getNodeId).thenAnswer((_) async => 'node-a');
      when(
        crdt.nextHlc,
      ).thenAnswer((_) async => Hlc(DateTime.utc(2030), 0, 'node-a'));
      trash = RecentlyDeletedRepository(db, crdt: crdt);
      await seedItem('i1', 'TV');
      await items.deleteItem('i1');
      final tombstoneHlc = (await itemRow('i1')).hlc;

      await trash.restoreItem('i1');

      final row = await itemRow('i1');
      expect(row.hlc.compareTo(tombstoneHlc), greaterThan(0));
      expect(row.nodeId, 'node-a');
    },
  );

  test(
    'rooms, policies, maintenance entries, categories and tags restore',
    () async {
      await db.locationDao.deleteRoom('room1');
      await trash.restoreRoom('room1');
      final room = await (db.select(
        db.rooms,
      )..where((t) => t.id.equals('room1'))).getSingle();
      expect(room.isDeleted, isFalse);

      await db.categoryDao.deleteCategory('cat1');
      await trash.restoreCategory('cat1');
      final cat = await (db.select(
        db.categories,
      )..where((t) => t.id.equals('cat1'))).getSingle();
      expect(cat.isDeleted, isFalse);

      await seedItem('i1', 'TV');
      await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              id: 't1',
              name: 'Gift',
              createdAt: t0,
              modifiedAt: t0,
            ),
          );
      await db.tagDao.setItemTags('i1', ['t1']);
      final tagged = await trash.itemsTagged('t1');
      await db.tagDao.deleteTag('t1');
      await trash.restoreTag('t1', itemIds: tagged);
      expect(await db.tagDao.getItemTagIds('i1'), ['t1']);
    },
  );
}

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  final now = DateTime(2025, 1, 1);

  setUp(() async {
    db = AppDatabase.memory();
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
            name: 'Garage',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  StorageContainersCompanion container(String id, String name) =>
      StorageContainersCompanion.insert(
        id: id,
        roomId: 'room1',
        name: name,
        createdAt: now,
        modifiedAt: now,
      );

  group('ContainerDao.watchByRoom', () {
    test('returns containers for the given room', () async {
      await db.containerDao.insert(container('c1', 'Shelf A'));
      await db.containerDao.insert(container('c2', 'Shelf B'));

      final result = await db.containerDao.watchByRoom('room1').first;
      expect(result.length, 2);
    });

    test('excludes soft-deleted containers', () async {
      await db.containerDao.insert(container('c1', 'Active'));
      await db.containerDao.insert(container('c2', 'Deleted'));
      await db.containerDao.softDelete('c2');

      final result = await db.containerDao.watchByRoom('room1').first;
      expect(result.length, 1);
      expect(result.first.name, 'Active');
    });

    test('returns empty for unknown room', () async {
      final result = await db.containerDao.watchByRoom('no-room').first;
      expect(result, isEmpty);
    });
  });

  group('ContainerDao.getById', () {
    test('returns container when it exists', () async {
      await db.containerDao.insert(container('c1', 'Bin A'));
      final result = await db.containerDao.getById('c1');
      expect(result?.name, 'Bin A');
    });

    test('returns null for unknown id', () async {
      final result = await db.containerDao.getById('nope');
      expect(result, isNull);
    });
  });

  group('ContainerDao.updateContainer', () {
    test('updates name and returns true', () async {
      await db.containerDao.insert(container('c1', 'Old Name'));
      final updated = await db.containerDao.updateContainer(
        StorageContainersCompanion(
          id: const Value('c1'),
          name: const Value('New Name'),
          modifiedAt: Value(DateTime(2025, 6, 1)),
        ),
      );
      expect(updated, isTrue);

      final result = await db.containerDao.getById('c1');
      expect(result?.name, 'New Name');
    });

    test('returns false for unknown id', () async {
      final updated = await db.containerDao.updateContainer(
        StorageContainersCompanion(
          id: const Value('nope'),
          name: const Value('X'),
          modifiedAt: Value(now),
        ),
      );
      expect(updated, isFalse);
    });
  });

  group('ContainerDao.softDelete', () {
    test('marks container as deleted', () async {
      await db.containerDao.insert(container('c1', 'To Delete'));
      await db.containerDao.softDelete('c1');

      final result = await db.containerDao.watchByRoom('room1').first;
      expect(result, isEmpty);
    });
  });
}

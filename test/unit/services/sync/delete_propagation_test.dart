import 'package:crdt/crdt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/sync/sync_stamp.dart';
import 'package:still_life/features/inventory/data/repositories/item_repository_impl.dart';
import 'package:still_life/features/inventory/data/repositories/photo_repository_impl.dart';
import 'package:still_life/features/locations/data/repositories/room_repository_impl.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:typed_data';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';
import 'package:still_life/services/storage/photo_storage_service.dart';
import 'package:still_life/services/sync/crdt_manager.dart';

import '../../../test_setup.dart';

class _MockPhotoStorage extends Mock implements PhotoStorageService {}

class _MockStorage extends Mock implements FlutterSecureStorage {}

/// A clock we set by hand, so "newer" is decided by the test and never by
/// two stamps landing in the same millisecond.
class _Clock extends Mock implements CrdtManager {
  _Clock(this.node);
  final String node;
  DateTime now = DateTime.utc(2030);

  @override
  Future<String> getNodeId() async => node;

  @override
  Future<Hlc> nextHlc() async => Hlc(now, 0, node);
}

/// Yellow paper §4: a row is applied over the local one only when its HLC is
/// strictly greater (L4), and an unstamped row blind-applies (L1, L3). A
/// delete written without a stamp therefore lost to any older edit, and an
/// edit written without a stamp overwrote any newer delete. Local writes
/// now stamp, so last-writer-wins decides, in both directions.
void main() {
  ensureSqlite3();

  late AppDatabase dbA, dbB;
  late _Clock clockA, clockB;
  late ItemRepositoryImpl repoA, repoB;

  Future<void> seed(AppDatabase db) async {
    final t = DateTime(2026);
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'p',
            name: 'Home',
            createdAt: t,
            modifiedAt: t,
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'r',
            propertyId: 'p',
            name: 'Den',
            createdAt: t,
            modifiedAt: t,
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'c',
            name: 'Things',
            createdAt: t,
            modifiedAt: t,
          ),
        );
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'i1',
            name: 'Lamp',
            categoryId: 'c',
            roomId: 'r',
            createdAt: t,
            modifiedAt: t,
          ),
        );
  }

  /// One direction of a sync: [from]'s rows merged into [to] under LWW.
  Future<void> push(AppDatabase from, AppDatabase to) async {
    final json = await JsonExportService(from).exportToJson();
    // The stamps here are set in 2030; the receiver's clock is too, or the
    // future-stamp bound would (rightly) hold every row back.
    final r = await ImportService(to, clock: () => DateTime.utc(2031))
        .importFromJson(json, lww: true);
    expect(r.isSuccess, isTrue);
  }

  Future<Item> row(AppDatabase db) =>
      (db.select(db.items)..where((t) => t.id.equals('i1'))).getSingle();

  Future<void> editOnB(String name) async {
    final current = (await repoB.getItem('i1')).value;
    final r = await repoB.updateItem(current.copyWith(name: name));
    expect(r.isSuccess, isTrue);
  }

  setUp(() async {
    dbA = AppDatabase.memory();
    dbB = AppDatabase.memory();
    await seed(dbA);
    await seed(dbB);
    final photos = _MockPhotoStorage();
    clockA = _Clock('node-a');
    clockB = _Clock('node-b');
    repoA = ItemRepositoryImpl(dbA, photos, stamp: SyncStamp(clockA));
    repoB = ItemRepositoryImpl(dbB, photos, stamp: SyncStamp(clockB));
  });

  tearDown(() async {
    await dbA.close();
    await dbB.close();
  });

  test('a delete on A wins over an older edit on B, both ways round', () async {
    clockB.now = DateTime.utc(2030, 1, 1, 10);
    await editOnB('Brass lamp');
    clockA.now = DateTime.utc(2030, 1, 1, 11);
    await repoA.deleteItem('i1');

    await push(dbB, dbA); // the older edit must not resurrect the item
    await push(dbA, dbB); // the delete must reach B

    expect((await row(dbA)).isDeleted, isTrue);
    expect((await row(dbB)).isDeleted, isTrue);
  });

  test(
    'an edit on B newer than the delete on A wins (LWW, not delete-wins)',
    () async {
      clockA.now = DateTime.utc(2030, 1, 1, 10);
      await repoA.deleteItem('i1');
      clockB.now = DateTime.utc(2030, 1, 1, 11);
      await editOnB('Brass lamp');

      await push(dbA, dbB);
      await push(dbB, dbA);

      for (final db in [dbA, dbB]) {
        final r = await row(db);
        expect(r.isDeleted, isFalse);
        expect(r.name, 'Brass lamp');
      }
    },
  );

  test(
    'a keystore failure never blocks a save: the write goes unstamped',
    () async {
      final storage = _MockStorage();
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenThrow(Exception('keystore unavailable'));
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(Exception('keystore unavailable'));
      final repo = ItemRepositoryImpl(
        dbA,
        _MockPhotoStorage(),
        stamp: SyncStamp(CrdtManager(storage)),
      );

      final r = await repo.deleteItem('i1');

      expect(r.isSuccess, isTrue);
      expect((await row(dbA)).isDeleted, isTrue);
    },
  );

  test(
    'deleting one photo leaves a stamped tombstone, not a missing row',
    () async {
      await dbA
          .into(dbA.photos)
          .insert(
            PhotosCompanion.insert(
              id: 'ph1',
              itemId: 'i1',
              filePath: '',
              bytes: Value(Uint8List.fromList([1, 2, 3])),
              capturedAt: DateTime(2026),
              createdAt: DateTime(2026),
              modifiedAt: DateTime(2026),
            ),
          );
      clockA.now = DateTime.utc(2030, 2);
      final r = await PhotoRepositoryImpl(
        dbA,
        stamp: SyncStamp(clockA),
      ).deletePhoto('ph1');
      expect(r.isSuccess, isTrue);

      final photo = await (dbA.select(
        dbA.photos,
      )..where((t) => t.id.equals('ph1'))).getSingleOrNull();
      // A hard delete gave peers nothing to merge; the photo came back.
      expect(photo, isNotNull);
      expect(photo!.isDeleted, isTrue);
      expect(photo.hlc, isNotEmpty);
      expect(photo.bytes, isNull, reason: 'a deleted photo keeps no picture');
    },
  );

  test('reordering rooms stamps each moved room, so the order syncs', () async {
    await dbA
        .into(dbA.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'r2',
            propertyId: 'p',
            name: 'Attic',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
    clockA.now = DateTime.utc(2030, 3);
    final r = await RoomRepositoryImpl(
      dbA,
      stamp: SyncStamp(clockA),
    ).reorderRooms(['r2', 'r']);
    expect(r.isSuccess, isTrue);

    final rows = await dbA.select(dbA.rooms).get();
    final byId = {for (final x in rows) x.id: x};
    expect(byId['r2']!.sortOrder, 0);
    expect(byId['r']!.sortOrder, 1);
    // An unstamped reorder kept each room's old stamp, so a peer's copy
    // (L5 tie, or blind-apply) won and the new order never arrived.
    expect(byId['r2']!.hlc, isNotEmpty);
    expect(byId['r']!.hlc, isNotEmpty);
    expect(byId['r']!.nodeId, 'node-a');
  });

  // The importer upserts profiles with the incoming row's own stamp (right:
  // an import must not re-stamp), but profiles sat outside the LWW filter,
  // so an OLDER profile from a peer overwrote a newer local rename.
  test(
    'an older profile from a peer does not overwrite a newer local one',
    () async {
      Future<void> put(AppDatabase db, String name, String hlc) => db
          .into(db.profiles)
          .insertOnConflictUpdate(
            ProfilesCompanion.insert(
              id: 'prof1',
              name: name,
              createdAt: DateTime(2026),
              modifiedAt: DateTime(2026),
              hlc: Value(hlc),
              nodeId: const Value('n'),
            ),
          );
      await put(dbB, 'Sam', Hlc(DateTime.utc(2030, 1), 0, 'node-b').toString());
      await put(
        dbA,
        'Samantha',
        Hlc(DateTime.utc(2030, 2), 0, 'node-a').toString(),
      );

      await push(dbB, dbA);

      final p = await (dbA.select(
        dbA.profiles,
      )..where((t) => t.id.equals('prof1'))).getSingle();
      expect(p.name, 'Samantha');

      await push(dbA, dbB);
      final q = await (dbB.select(
        dbB.profiles,
      )..where((t) => t.id.equals('prof1'))).getSingle();
      expect(q.name, 'Samantha', reason: 'the newer rename still propagates');
    },
  );

  test('choosing a primary photo stamps both photos it changes', () async {
    for (final (id, primary) in [('ph1', true), ('ph2', false)]) {
      await dbA
          .into(dbA.photos)
          .insert(
            PhotosCompanion.insert(
              id: id,
              itemId: 'i1',
              filePath: '',
              isPrimary: Value(primary),
              capturedAt: DateTime(2026),
              createdAt: DateTime(2026),
              modifiedAt: DateTime(2026),
            ),
          );
    }
    clockA.now = DateTime.utc(2030, 4);
    await PhotoRepositoryImpl(
      dbA,
      stamp: SyncStamp(clockA),
    ).setPrimaryPhoto('i1', 'ph2');

    final rows = {for (final p in await dbA.select(dbA.photos).get()) p.id: p};
    expect(rows['ph2']!.isPrimary, isTrue);
    expect(rows['ph1']!.isPrimary, isFalse);
    expect(rows['ph1']!.hlc, isNotEmpty);
    expect(rows['ph2']!.hlc, isNotEmpty);
  });
}

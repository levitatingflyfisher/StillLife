import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/sync/changeset.dart';
import 'package:still_life/services/sync/crdt_manager.dart';
import 'package:still_life/services/sync/merge_engine.dart';

import '../../../test_setup.dart';

class _Clock extends Mock implements CrdtManager {
  @override
  Future<Hlc> mergeHlc(String remoteHlcStr) async => Hlc.zero('local');
}

/// SQLite enforces the declared foreign keys (PRAGMA foreign_keys = ON), so
/// the database itself refuses an orphan. On the sync path a row whose parent
/// is held back (stamped too far ahead) or missing is held back with it, so a
/// sync never fails and never lands an orphan; it lands on a later sync once
/// the parent does.
void main() {
  ensureSqlite3();

  final now = DateTime.utc(2026, 9, 28, 12);
  String stamp(DateTime t) => Hlc(t, 0, 'peer').toString();
  final ok = stamp(DateTime.utc(2026, 9, 1));
  final ahead = now.add(const Duration(minutes: 30));

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    final t = DateTime.utc(2026);
    await db.into(db.properties).insert(PropertiesCompanion.insert(
        id: 'p', name: 'Home', createdAt: t, modifiedAt: t));
    await db.into(db.rooms).insert(RoomsCompanion.insert(
        id: 'r', propertyId: 'p', name: 'Den', createdAt: t, modifiedAt: t));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'c', name: 'Things', createdAt: t, modifiedAt: t));
  });
  tearDown(() => db.close());

  Map<String, dynamic> item(String id, String hlc) => {
        'id': id, 'name': 'Lamp', 'categoryId': 'c', 'roomId': 'r',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'modifiedAt': '2026-01-01T00:00:00.000Z', 'hlc': hlc,
      };
  Map<String, dynamic> photo(String id, String itemId) => {
        'id': id, 'itemId': itemId, 'filePath': '',
        'capturedAt': '2026-01-01T00:00:00.000Z',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'modifiedAt': '2026-01-01T00:00:00.000Z', 'hlc': ok,
      };

  Future<MergeResult> sync(DateTime at, Map<String, dynamic> data) =>
      MergeEngine(
        importService: ImportService(db, clock: () => at),
        crdtManager: _Clock(),
      ).apply(SyncChangeset(
          senderNodeId: 'peer', senderHlc: stamp(at), data: data));

  Future<int> count(String table, String id) async => (await db
          .customSelect('SELECT 1 FROM $table WHERE id = ?',
              variables: [Variable<String>(id)])
          .get())
      .length;

  test('foreign keys are enforced', () async {
    final r = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(r.data.values.single, 1);
  });

  test('a child of a held-back parent is held back too, then lands', () async {
    final data = {
      'items': [item('i1', stamp(ahead))],
      'photos': [photo('ph1', 'i1')],
    };
    final r = await sync(now, data);
    expect(r.isSuccess, isTrue, reason: r.error);
    expect(await count('items', 'i1'), 0);
    expect(await count('photos', 'ph1'), 0);

    final later = await sync(ahead, data);
    expect(later.isSuccess, isTrue, reason: later.error);
    expect(await count('items', 'i1'), 1);
    expect(await count('photos', 'ph1'), 1);
  });

  test('a held-back parent holds back grandchildren too', () async {
    final r = await sync(now, {
      'rooms': [
        {
          'id': 'r2', 'propertyId': 'p', 'name': 'Attic',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'modifiedAt': '2026-01-01T00:00:00.000Z', 'hlc': stamp(ahead),
        }
      ],
      'items': [
        {...item('i2', ok), 'roomId': 'r2'}
      ],
      'photos': [photo('ph2', 'i2')],
    });
    expect(r.isSuccess, isTrue, reason: r.error);
    expect(await count('rooms', 'r2'), 0);
    expect(await count('items', 'i2'), 0);
    expect(await count('photos', 'ph2'), 0);
  });

  test('a child whose parent is nowhere is held back, not a failed sync',
      () async {
    final r = await sync(now, {
      'items': [item('i3', ok)],
      'photos': [photo('ph3', 'missing')],
    });
    expect(r.isSuccess, isTrue, reason: r.error);
    expect(await count('items', 'i3'), 1);
    expect(await count('photos', 'ph3'), 0);
  });

  test('a file import with an orphan fails closed, writing nothing', () async {
    final r = await ImportService(db, clock: () => now).importFromJson(
      json.encode({
        'app': 'still_life',
        'version': '1.0',
        'data': {
          'items': [item('i4', ok)],
          'photos': [photo('ph4', 'missing')],
        },
      }),
    );
    expect(r.isSuccess, isFalse);
    expect(await count('items', 'i4'), 0);
  });
}

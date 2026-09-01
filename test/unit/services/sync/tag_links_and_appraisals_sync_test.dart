import 'package:crdt/crdt.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/sync/sync_stamp.dart';
import 'package:still_life/features/appraisal/data/repositories/appraisal_repository_impl.dart';
import 'package:still_life/features/appraisal/domain/entities/appraisal.dart';
import 'package:still_life/features/inventory/data/repositories/tag_repository_impl.dart';
import 'package:still_life/services/database/database.dart' hide Appraisal;
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';
import 'package:still_life/services/sync/crdt_manager.dart';

import '../../../test_setup.dart';

/// A clock set by hand, so "newer" is decided by the test.
class _Clock extends Mock implements CrdtManager {
  _Clock(this.node);
  final String node;
  DateTime now = DateTime.utc(2030);
  var _counter = 0;

  @override
  Future<String> getNodeId() async => node;

  @override
  Future<Hlc> nextHlc() async => Hlc(now, _counter++, node);
}

/// Tag links (item_tags) and appraisals used to be last-RECEIVED-wins on
/// sync, and tag links were hard-deleted and unstamped, so a removed tag
/// came back from any peer that still had it. Both now merge by the same
/// stamped last-writer-wins rule as every other row. Tag links are an
/// LWW-element-set: one row per (item, tag) pair with a stamp and a
/// tombstone, which is exactly what the table's composite key holds.
void main() {
  ensureSqlite3();

  late AppDatabase dbA, dbB;
  late _Clock clockA, clockB;

  Future<void> seed(AppDatabase db) async {
    final t = DateTime.utc(2026);
    await db.into(db.properties).insert(PropertiesCompanion.insert(
        id: 'p', name: 'Home', createdAt: t, modifiedAt: t));
    await db.into(db.rooms).insert(RoomsCompanion.insert(
        id: 'r', propertyId: 'p', name: 'Den', createdAt: t, modifiedAt: t));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'c', name: 'Things', createdAt: t, modifiedAt: t));
    await db.into(db.items).insert(ItemsCompanion.insert(
        id: 'i1', name: 'Lamp', categoryId: 'c', roomId: 'r',
        createdAt: t, modifiedAt: t));
    for (final tag in ['t1', 't2']) {
      await db.into(db.tags).insert(TagsCompanion.insert(
          id: tag, name: tag, createdAt: t, modifiedAt: t));
    }
  }

  Future<void> push(AppDatabase from, AppDatabase to) async {
    final json = await JsonExportService(from).exportToJson();
    final r = await ImportService(to, clock: () => DateTime.utc(2031))
        .importFromJson(json, lww: true);
    expect(r.isSuccess, isTrue, reason: r.isSuccess ? null : '$r');
  }

  setUp(() async {
    dbA = AppDatabase.memory();
    dbB = AppDatabase.memory();
    await seed(dbA);
    await seed(dbB);
    clockA = _Clock('node-a');
    clockB = _Clock('node-b');
  });

  tearDown(() async {
    await dbA.close();
    await dbB.close();
  });

  group('tag links', () {
    TagRepositoryImpl repo(AppDatabase db, _Clock c) =>
        TagRepositoryImpl(db, stamp: SyncStamp(c));
    Future<List<String>> links(AppDatabase db) async =>
        (await db.tagDao.getItemTagIds('i1'))..sort();

    Future<void> tag(AppDatabase db, _Clock c, DateTime at, List<String> ids) async {
      c.now = at;
      final r = await repo(db, c).setItemTags('i1', ids);
      expect(r.isSuccess, isTrue);
    }

    test('an added tag reaches the other device', () async {
      await tag(dbA, clockA, DateTime.utc(2030, 1, 1, 9), ['t1']);
      await push(dbA, dbB);
      expect(await links(dbB), ['t1']);
    });

    test('a removed tag stays removed when a stale peer syncs back', () async {
      await tag(dbA, clockA, DateTime.utc(2030, 1, 1, 9), ['t1', 't2']);
      await push(dbA, dbB);
      await tag(dbA, clockA, DateTime.utc(2030, 1, 1, 10), ['t2']);

      await push(dbB, dbA); // B still has t1: must not bring it back
      await push(dbA, dbB); // the removal must reach B

      expect(await links(dbA), ['t2']);
      expect(await links(dbB), ['t2']);
    });

    test('remove vs re-add: the later one wins, both ways round', () async {
      await tag(dbA, clockA, DateTime.utc(2030, 1, 1, 9), ['t1']);
      await push(dbA, dbB);

      // B removes then re-adds at 10:00; A removes at 11:00 → removed.
      await tag(dbB, clockB, DateTime.utc(2030, 1, 1, 10), []);
      await tag(dbB, clockB, DateTime.utc(2030, 1, 1, 10, 1), ['t1']);
      await tag(dbA, clockA, DateTime.utc(2030, 1, 1, 11), []);
      await push(dbB, dbA);
      await push(dbA, dbB);
      expect(await links(dbA), isEmpty);
      expect(await links(dbB), isEmpty);

      // Now A re-adds at 13:00 after B's removal at 12:00 → present.
      await tag(dbB, clockB, DateTime.utc(2030, 1, 1, 12), []);
      await tag(dbA, clockA, DateTime.utc(2030, 1, 1, 13), ['t1']);
      await push(dbA, dbB);
      await push(dbB, dbA);
      expect(await links(dbA), ['t1']);
      expect(await links(dbB), ['t1']);
    });

    test('deleting a tag removes its links on the other device too', () async {
      await tag(dbA, clockA, DateTime.utc(2030, 1, 1, 9), ['t1']);
      await push(dbA, dbB);
      clockA.now = DateTime.utc(2030, 1, 1, 10);
      await repo(dbA, clockA).deleteTag('t1');
      await push(dbB, dbA);
      await push(dbA, dbB);
      expect(await links(dbA), isEmpty);
      expect(await links(dbB), isEmpty);
    });
  });

  group('appraisals', () {
    AppraisalRepositoryImpl repo(AppDatabase db, _Clock c) =>
        AppraisalRepositoryImpl(db, stamp: SyncStamp(c));
    Future<bool> deleted(AppDatabase db) async => (await (db.select(
          db.appraisals,
        )..where((t) => t.id.equals('a1'))).getSingle()).isDeleted;

    Appraisal appraisal() => Appraisal(
          id: 'a1',
          itemId: 'i1',
          mode: AppraisalMode.resale,
          valueCents: 10000,
          currency: 'USD',
          confidence: 0.8,
          sources: const [],
          itemModelKey: 'lamp|good',
          countryCode: 'US',
          queriedAt: DateTime.utc(2030),
          expiresAt: DateTime.utc(2031),
        );

    for (final deleter in ['A', 'B']) {
      test('a delete on $deleter survives the other side\'s stale copy',
          () async {
        clockA.now = DateTime.utc(2030, 1, 1, 9);
        expect((await repo(dbA, clockA).save(appraisal())).isSuccess, isTrue);
        await push(dbA, dbB);

        final (del, delDb, other) = deleter == 'A'
            ? (clockA, dbA, dbB)
            : (clockB, dbB, dbA);
        del.now = DateTime.utc(2030, 1, 1, 10);
        expect((await repo(delDb, del).delete('a1')).isSuccess, isTrue);

        await push(other, delDb); // stale live copy must not resurrect it
        await push(delDb, other); // the tombstone must reach the other side
        expect(await deleted(dbA), isTrue);
        expect(await deleted(dbB), isTrue);
      });
    }

    test('a stale remote row does not overwrite a newer local one', () async {
      clockA.now = DateTime.utc(2030, 1, 1, 9);
      await repo(dbA, clockA).save(appraisal());
      await push(dbA, dbB);
      // A newer local value on B (as a sync of a later appraisal would land).
      await (dbB.update(dbB.appraisals)..where((t) => t.id.equals('a1'))).write(
        AppraisalsCompanion(
          valueCents: const Value(20000),
          hlc: Value(Hlc(DateTime.utc(2030, 1, 1, 10), 0, 'node-b').toString()),
        ),
      );
      await push(dbA, dbB);
      final b = await (dbB.select(dbB.appraisals)
            ..where((t) => t.id.equals('a1')))
          .getSingle();
      expect(b.valueCents, 20000);
    });
  });
}

import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:drift/drift.dart' show Value, Variable;
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

/// Decision 5 (A): on the sync path a row with no stamp can only fill a
/// hole, never overwrite (Peckish's `_wins`). Before, `hlc: ""` bypassed
/// last-writer-wins entirely, so any peer could clobber any row by omitting
/// the stamp. An explicit file import still accepts pre-stamp files.
void main() {
  ensureSqlite3();

  // The test decides what "now" is; nothing here reads the real clock.
  final now = DateTime.utc(2026, 9, 28, 12);
  String stamp(DateTime t, [String node = 'peer']) => Hlc(t, 0, node).toString();
  final localStamp = stamp(DateTime.utc(2026, 9, 1), 'local');

  late AppDatabase db;
  late ImportService importer;
  late MergeEngine engine;

  setUp(() {
    db = AppDatabase.memory();
    importer = ImportService(db, clock: () => now);
    engine = MergeEngine(importService: importer, crdtManager: _Clock());
  });
  tearDown(() => db.close());

  Map<String, dynamic> category(String id, String name, String hlc) => {
        'id': id,
        'name': name,
        'createdAt': DateTime.utc(2026).toIso8601String(),
        'modifiedAt': DateTime.utc(2026).toIso8601String(),
        'hlc': hlc,
      };

  Future<void> putLocal(String id, String name, String hlc) async {
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: id,
            name: name,
            createdAt: DateTime.utc(2026),
            modifiedAt: DateTime.utc(2026),
            hlc: Value(hlc),
          ),
        );
  }

  Future<String?> nameOf(String id) async {
    final rows = await db
        .customSelect('SELECT name FROM categories WHERE id = ?',
            variables: [Variable<String>(id)])
        .get();
    return rows.isEmpty ? null : rows.first.read<String>('name');
  }

  Future<void> lanSync(List<Map<String, dynamic>> categories) async {
    final r = await engine.apply(SyncChangeset(
      senderNodeId: 'peer',
      senderHlc: stamp(now),
      data: {'categories': categories},
    ));
    expect(r.isSuccess, isTrue, reason: r.error);
  }

  group('LAN sync', () {
    test('an unstamped row does not overwrite a stamped local row', () async {
      await putLocal('c1', 'Mine', localStamp);
      await lanSync([category('c1', 'Theirs', '')]);
      expect(await nameOf('c1'), 'Mine');
    });

    test('an unstamped row still fills a hole', () async {
      await lanSync([category('c2', 'New', '')]);
      expect(await nameOf('c2'), 'New');
    });

    test('a stamp that does not parse counts as no stamp', () async {
      // 'zzz' sorts after every real stamp, so as a string it won forever.
      await putLocal('c1', 'Mine', localStamp);
      await lanSync([category('c1', 'Theirs', 'zzz')]);
      expect(await nameOf('c1'), 'Mine');
    });

    test('a garbage stamp that filled a hole does not freeze the row',
        () async {
      await lanSync([category('c3', 'First', 'zzz')]);
      expect(await nameOf('c3'), 'First');
      await lanSync([category('c3', 'Real', stamp(DateTime.utc(2026, 9, 2)))]);
      expect(await nameOf('c3'), 'Real');
    });

    test('a stamped row overwrites an unstamped local row', () async {
      await putLocal('c1', 'Mine', '');
      await lanSync([category('c1', 'Theirs', stamp(DateTime.utc(2026, 9, 2)))]);
      expect(await nameOf('c1'), 'Theirs');
    });

    test('a newer stamp still wins, an older one still loses', () async {
      await putLocal('c1', 'Mine', localStamp);
      await putLocal('c2', 'Mine', localStamp);
      await lanSync([
        category('c1', 'Newer', stamp(DateTime.utc(2026, 9, 2))),
        category('c2', 'Older', stamp(DateTime.utc(2026, 8, 1))),
      ]);
      expect(await nameOf('c1'), 'Newer');
      expect(await nameOf('c2'), 'Mine');
    });
  });

  group('future-clock bound', () {
    test('is ten minutes (sync kernel design §3.2)', () {
      expect(ImportService.maxFutureSkew, const Duration(minutes: 10));
    });

    test('a row stamped beyond the bound is held back, even into a hole',
        () async {
      final ahead = now.add(const Duration(minutes: 11));
      await putLocal('c1', 'Mine', localStamp);
      await lanSync([
        category('c1', 'Future', stamp(ahead)),
        category('c2', 'Future', stamp(ahead)),
      ]);
      expect(await nameOf('c1'), 'Mine');
      expect(await nameOf('c2'), isNull);
    });

    test('a row stamped within the bound applies', () async {
      final ahead = now.add(const Duration(minutes: 9));
      await putLocal('c1', 'Mine', localStamp);
      await lanSync([category('c1', 'Soon', stamp(ahead))]);
      expect(await nameOf('c1'), 'Soon');
    });

    test('the held-back row applies once local time catches up', () async {
      final ahead = now.add(const Duration(minutes: 30));
      await lanSync([category('c2', 'Future', stamp(ahead))]);
      expect(await nameOf('c2'), isNull);

      final later = MergeEngine(
        importService: ImportService(db, clock: () => ahead),
        crdtManager: _Clock(),
      );
      await later.apply(SyncChangeset(
        senderNodeId: 'peer',
        senderHlc: stamp(ahead),
        data: {
          'categories': [category('c2', 'Future', stamp(ahead))],
        },
      ));
      expect(await nameOf('c2'), 'Future');
    });
  });

  group('explicit file import', () {
    String file(List<Map<String, dynamic>> categories) => json.encode({
          'app': 'still_life',
          'version': '1.0',
          'data': {'categories': categories},
        });

    test('still accepts a pre-stamp file', () async {
      await putLocal('c1', 'Mine', localStamp);
      final r = await importer.importFromJson(file([category('c1', 'Old', '')]));
      expect(r.isSuccess, isTrue);
      expect(await nameOf('c1'), 'Old');
    });

    test('counts the unstamped rows so the UI can warn first', () {
      final f = file([
        category('c1', 'Old', ''),
        category('c2', 'Old', stamp(DateTime.utc(2026, 9, 2))),
        category('c3', 'Old', 'zzz'),
      ]);
      expect(ImportService.countUnstampedRows(f), 2);
    });

    test('a file with every row stamped needs no warning', () {
      final f = file([category('c1', 'New', stamp(DateTime.utc(2026, 9, 2)))]);
      expect(ImportService.countUnstampedRows(f), 0);
    });
  });
}

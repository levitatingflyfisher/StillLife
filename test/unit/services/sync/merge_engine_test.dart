import 'package:crdt/crdt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/sync/changeset.dart';
import 'package:still_life/services/sync/crdt_manager.dart';
import 'package:still_life/services/sync/merge_engine.dart';
import 'package:drift/drift.dart' show Value;
import 'package:still_life/services/database/database.dart';

import '../../../test_setup.dart';

class _MockImportService extends Mock implements ImportService {}

class _MockCrdtManager extends Mock implements CrdtManager {}

void main() {
  ensureSqlite3();

  setUpAll(() {
    registerFallbackValue(Hlc.zero(''));
  });

  late _MockImportService importService;

  setUp(() {
    importService = _MockImportService();
  });

  SyncChangeset makeChangeset({
    Map<String, dynamic>? data,
    String senderNodeId = 'remote-node',
    String senderHlc = '2025-01-01T00:00:00.000Z:0@remote-node',
  }) => SyncChangeset(
    senderNodeId: senderNodeId,
    senderHlc: senderHlc,
    data:
        data ??
        {
          'items': <dynamic>[],
          'properties': <dynamic>[],
          'rooms': <dynamic>[],
          'categories': <dynamic>[],
          'tags': <dynamic>[],
          'itemTags': <dynamic>[],
          'photos': <dynamic>[],
          'receipts': <dynamic>[],
          'priceHistory': <dynamic>[],
          'policies': <dynamic>[],
          'maintenanceLogs': <dynamic>[],
        },
  );

  group('MergeEngine.apply', () {
    test('success: returns recordsApplied from ImportSummary', () async {
      when(
        () => importService.importFromJson(any(), lww: any(named: 'lww')),
      ).thenAnswer((_) async => const Success(ImportSummary(items: 3)));

      // Use a manager that doesn't throw on mergeHlc
      final silentCrdt = _MockCrdtManager();
      when(
        () => silentCrdt.mergeHlc(any()),
      ).thenAnswer((_) async => Hlc.zero(''));
      final localEngine = MergeEngine(
        importService: importService,
        crdtManager: silentCrdt,
      );

      final result = await localEngine.apply(makeChangeset());

      expect(result.isSuccess, isTrue);
      expect(result.recordsApplied, 3);
    });

    test('failure: returns error from ImportService', () async {
      when(
        () => importService.importFromJson(any(), lww: any(named: 'lww')),
      ).thenAnswer((_) async => const Err(ImportFailure('bad json')));
      final silentCrdt = _MockCrdtManager();
      when(
        () => silentCrdt.mergeHlc(any()),
      ).thenAnswer((_) async => Hlc.zero(''));

      final localEngine = MergeEngine(
        importService: importService,
        crdtManager: silentCrdt,
      );

      final result = await localEngine.apply(makeChangeset());

      expect(result.isSuccess, isFalse);
      expect(result.error, 'bad json');
      expect(result.recordsApplied, 0);
    });

    test('exception: wraps in MergeResult with error', () async {
      when(
        () => importService.importFromJson(any(), lww: any(named: 'lww')),
      ).thenThrow(Exception('network timeout'));
      final silentCrdt = _MockCrdtManager();
      when(
        () => silentCrdt.mergeHlc(any()),
      ).thenAnswer((_) async => Hlc.zero(''));

      final localEngine = MergeEngine(
        importService: importService,
        crdtManager: silentCrdt,
      );

      final result = await localEngine.apply(makeChangeset());

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('network timeout'));
    });

    test('SyncChangeset serialises and deserialises round-trip', () {
      final cs = makeChangeset(senderNodeId: 'abc', senderHlc: 'hlc-val');
      final json = cs.toJson();
      final cs2 = SyncChangeset.fromJson(json);

      expect(cs2.senderNodeId, 'abc');
      expect(cs2.senderHlc, 'hlc-val');
    });
  });

  group('MergeEngine.apply LWW (real DB, real ImportService)', () {
    late AppDatabase db;
    late MergeEngine realEngine;

    // HLC strings sort lexicographically; @A rows are strictly newer than @B.
    const newerHlc = '2025-06-01T00:00:00.000Z-0000-0@A';
    const olderHlc = '2025-01-01T00:00:00.000Z-0000-0@B';

    setUp(() async {
      db = AppDatabase.memory();
      final crdt = _MockCrdtManager();
      when(() => crdt.mergeHlc(any())).thenAnswer((_) async => Hlc.zero(''));
      realEngine = MergeEngine(importService: ImportService(db), crdtManager: crdt);

      final t0 = DateTime(2025, 6, 1);
      await db.into(db.properties).insert(PropertiesCompanion.insert(
          id: 'prop1', name: 'Home', createdAt: t0, modifiedAt: t0));
      await db.into(db.rooms).insert(RoomsCompanion.insert(
          id: 'room1', propertyId: 'prop1', name: 'Living', createdAt: t0, modifiedAt: t0));
      await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat1', name: 'Electronics', createdAt: t0, modifiedAt: t0));
      // Local item x: a NEW edit (newer HLC).
      await db.into(db.items).insert(ItemsCompanion.insert(
          id: 'x', name: 'NewName', categoryId: 'cat1', roomId: 'room1',
          createdAt: t0, modifiedAt: t0, hlc: const Value(newerHlc)));
      // Local item y: a NEWER tombstone (deleted, newer HLC).
      await db.into(db.items).insert(ItemsCompanion.insert(
          id: 'y', name: 'Gone', categoryId: 'cat1', roomId: 'room1',
          createdAt: t0, modifiedAt: t0, hlc: const Value(newerHlc),
          isDeleted: const Value(true)));
    });

    tearDown(() => db.close());

    Map<String, dynamic> remoteItem(String id, String name, bool deleted) => {
          'id': id, 'name': name, 'categoryId': 'cat1', 'roomId': 'room1',
          'createdAt': '2025-01-01T00:00:00.000',
          'modifiedAt': '2025-01-01T00:00:00.000',
          'hlc': olderHlc, 'isDeleted': deleted,
        };

    test('a stale peer cannot overwrite newer edits or resurrect tombstones',
        () async {
      final cs = makeChangeset(data: {
        'items': [
          remoteItem('x', 'OldName', false), // older → must NOT overwrite
          remoteItem('y', 'Back', false), // older un-delete → must NOT resurrect
          remoteItem('z', 'Fresh', false), // brand new → must insert
        ],
      });

      final result = await realEngine.apply(cs);
      expect(result.isSuccess, isTrue, reason: result.error);

      final x = await (db.select(db.items)..where((t) => t.id.equals('x'))).getSingle();
      expect(x.name, 'NewName',
          reason: 'a stale remote must not overwrite a newer local edit');
      final y = await (db.select(db.items)..where((t) => t.id.equals('y'))).getSingle();
      expect(y.isDeleted, isTrue,
          reason: 'a stale remote must not resurrect a newer tombstone');
      final z = await (db.select(db.items)..where((t) => t.id.equals('z'))).getSingleOrNull();
      expect(z, isNotNull, reason: 'a brand-new remote row must still be inserted');
      expect(z!.name, 'Fresh');
    });
  });
}

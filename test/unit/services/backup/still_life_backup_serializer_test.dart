import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:still_life/services/backup/still_life_backup_serializer.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';

import '../../../test_setup.dart';

Future<void> _seedItem(AppDatabase db, {String suffix = 'a'}) async {
  final now = DateTime(2026);
  await db.into(db.properties).insert(PropertiesCompanion.insert(
        id: 'p_$suffix',
        name: 'Home',
        createdAt: now,
        modifiedAt: now,
      ));
  await db.into(db.rooms).insert(RoomsCompanion.insert(
        id: 'r_$suffix',
        propertyId: 'p_$suffix',
        name: 'Room',
        createdAt: now,
        modifiedAt: now,
      ));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'c_$suffix',
        name: 'Cat',
        createdAt: now,
        modifiedAt: now,
      ));
  await db.into(db.items).insert(ItemsCompanion.insert(
        id: 'item_$suffix',
        name: 'Item',
        categoryId: 'c_$suffix',
        roomId: 'r_$suffix',
        createdAt: now,
        modifiedAt: now,
      ));
}

Future<void> _seedPhotoWithBytes(AppDatabase db, List<int> bytes) async {
  final now = DateTime(2026);
  await db.into(db.photos).insert(PhotosCompanion.insert(
        id: 'photo_1',
        itemId: 'item_a',
        filePath: '',
        bytes: Value(Uint8List.fromList(bytes)),
        capturedAt: now,
        createdAt: now,
        modifiedAt: now,
      ));
}

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late StillLifeBackupSerializer serializer;

  setUp(() {
    db = AppDatabase.memory();
    serializer = StillLifeBackupSerializer(
      exportService: JsonExportService(db),
      importService: ImportService(db),
    );
  });

  tearDown(() => db.close());

  test('dumpAll emits the still_life JSON envelope', () async {
    await _seedItem(db);
    final bytes = await serializer.dumpAll();
    final envelope = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    expect(envelope['app'], 'still_life');
    expect(envelope['photosIncluded'], false);
  });

  group('envelope v2 keys (BACKUP_RETENTION_SPEC §2.F, additive)', () {
    test('dumpAll adds createdAt (ISO8601 UTC) + int schemaVersion 1', () async {
      await _seedItem(db);
      final bytes = await serializer.dumpAll();
      final envelope = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;

      expect(envelope['schemaVersion'], 1);
      final createdAt = envelope['createdAt'];
      expect(createdAt, isA<String>());
      final parsed = DateTime.parse(createdAt as String);
      expect(parsed.isUtc, isTrue, reason: 'createdAt must be stamped UTC');
      expect(
        DateTime.now().toUtc().difference(parsed).inMinutes.abs() < 5,
        isTrue,
        reason: 'createdAt must be the export moment',
      );
    });

    test('dumpAll KEEPS every legacy key old readers gate on', () async {
      await _seedItem(db);
      final bytes = await serializer.dumpAll();
      final envelope = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;

      // The shipped app gates restore on app == 'still_life' and a string
      // major version; removing/renaming any of these breaks old installs
      // restoring NEW backups (wire-compat law).
      expect(envelope['version'], '1.0');
      expect(envelope['app'], 'still_life');
      expect(envelope['exportedAt'], isA<String>());
      expect(envelope['data'], isA<Map<String, dynamic>>());
      expect(envelope['photosIncluded'], false);
    });

    test('a LEGACY envelope without the new keys still restores', () async {
      // Simulate a backup written by the shipped (pre-v2) app: exactly
      // today's envelope minus the additive keys.
      await _seedItem(db);
      final dump = await serializer.dumpAll();
      final legacy =
          json.decode(utf8.decode(dump)) as Map<String, dynamic>
            ..remove('createdAt')
            ..remove('schemaVersion');
      final legacyBytes = Uint8List.fromList(utf8.encode(json.encode(legacy)));

      final fresh = AppDatabase.memory();
      addTearDown(fresh.close);
      final freshSerializer = StillLifeBackupSerializer(
        exportService: JsonExportService(fresh),
        importService: ImportService(fresh),
      );
      await freshSerializer.restoreAll(legacyBytes);

      final items = await fresh.select(fresh.items).get();
      expect(items.map((i) => i.id), contains('item_a'));
    });
  });

  // The gating regression guard (advisor): a metadata restore must NOT wipe
  // photo BLOBs the backup deliberately omits.
  test('restoreAll preserves existing photo BLOBs (upsert, not wipe)', () async {
    await _seedItem(db);
    await _seedPhotoWithBytes(db, [1, 2, 3, 4, 5]);

    final dump = await serializer.dumpAll();
    await serializer.restoreAll(dump);

    final photo = await (db.select(db.photos)
          ..where((p) => p.id.equals('photo_1')))
        .getSingle();
    expect(photo.bytes, Uint8List.fromList([1, 2, 3, 4, 5]),
        reason: 'metadata restore must not null out photo bytes');
  });

  test('round-trips inventory into a fresh database', () async {
    await _seedItem(db);
    final dump = await serializer.dumpAll();

    final fresh = AppDatabase.memory();
    addTearDown(fresh.close);
    final freshSerializer = StillLifeBackupSerializer(
      exportService: JsonExportService(fresh),
      importService: ImportService(fresh),
    );
    await freshSerializer.restoreAll(dump);

    final items = await fresh.select(fresh.items).get();
    expect(items.map((i) => i.id), contains('item_a'));
  });

  group('envelope checks (§2.8)', () {
    test('rejects a payload for a different app', () {
      final blob = Uint8List.fromList(utf8.encode(
        json.encode({'app': 'lullaby', 'version': '1.0', 'data': {}}),
      ));
      expect(
        () => serializer.restoreAll(blob),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects a future schema version with BackupSchemaException', () {
      final blob = Uint8List.fromList(utf8.encode(
        json.encode({'app': 'still_life', 'version': '2.0', 'data': {}}),
      ));
      expect(
        () => serializer.restoreAll(blob),
        throwsA(isA<BackupSchemaException>()),
      );
    });

    test('rejects a non-JSON payload with BackupFormatException', () {
      final blob = Uint8List.fromList(utf8.encode('not json at all'));
      expect(
        () => serializer.restoreAll(blob),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects a future INT schemaVersion even when version is 1.0', () {
      // The v2 gate: a newer app bumps the int schemaVersion; the legacy
      // string may lag. BackupEnvelope.unwrap must catch this in addition
      // to the string-major gate.
      final blob = Uint8List.fromList(utf8.encode(
        json.encode({
          'app': 'still_life',
          'version': '1.0',
          'schemaVersion': 99,
          'data': <String, dynamic>{},
        }),
      ));
      expect(
        () => serializer.restoreAll(blob),
        throwsA(isA<BackupSchemaException>()),
      );
    });
  });

  group('preview-before-restore (BACKUP_RETENTION_SPEC §2.D)', () {
    test('serializer is previewable', () {
      expect(serializer, isA<PreviewableBackupSerializer>());
    });

    test('describeBackup reports envelope metadata + table counts', () async {
      await _seedItem(db);
      final manifest = await (serializer as PreviewableBackupSerializer)
          .describeBackup(await serializer.dumpAll());

      expect(manifest.appId, 'still_life');
      expect(manifest.schemaVersion, 1);
      expect(manifest.createdAt, isNotNull);
      expect(manifest.tableCounts['items'], 1);
      expect(manifest.tableCounts['rooms'], 1);
    });

    test('describeBackup throws exactly what restoreAll would (shared gate)',
        () async {
      final previewable = serializer as PreviewableBackupSerializer;

      Uint8List blob(Map<String, dynamic> envelope) =>
          Uint8List.fromList(utf8.encode(json.encode(envelope)));

      await expectLater(
        previewable.describeBackup(
            blob({'app': 'lullaby', 'version': '1.0', 'data': {}})),
        throwsA(isA<BackupFormatException>()),
        reason: 'wrong app must reject in preview too',
      );
      await expectLater(
        previewable.describeBackup(
            blob({'app': 'still_life', 'version': '2.0', 'data': {}})),
        throwsA(isA<BackupSchemaException>()),
        reason: 'future string major must reject in preview too',
      );
      await expectLater(
        previewable.describeBackup(blob({
          'app': 'still_life',
          'version': '1.0',
          'schemaVersion': 99,
          'data': {},
        })),
        throwsA(isA<BackupSchemaException>()),
        reason: 'future int schemaVersion must reject in preview too',
      );
      await expectLater(
        previewable
            .describeBackup(Uint8List.fromList(utf8.encode('not json'))),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('describeBackup never writes', () async {
      await _seedItem(db);
      final dump = await serializer.dumpAll();

      final fresh = AppDatabase.memory();
      addTearDown(fresh.close);
      final freshSerializer = StillLifeBackupSerializer(
        exportService: JsonExportService(fresh),
        importService: ImportService(fresh),
      );
      await (freshSerializer as PreviewableBackupSerializer)
          .describeBackup(dump);

      expect(await fresh.select(fresh.items).get(), isEmpty,
          reason: 'a dry-run parse must not import anything');
    });
  });
}

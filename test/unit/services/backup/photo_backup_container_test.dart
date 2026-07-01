import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:still_life/services/backup/photo_backup_container.dart';
import 'package:still_life/services/backup/still_life_backup_serializer.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';

import '../../../test_setup.dart';

// A tiny valid 1x1 PNG (real bytes, per the brief).
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

final _key = Uint8List.fromList(List.generate(32, (i) => (i * 7) & 0xFF));
final _receiptImg = Uint8List.fromList(List.generate(64, (i) => (i * 3) & 0xFF));

PhotoBackupContainer _container(AppDatabase db, {int? maxEntries}) {
  final repo = BackupRepository(
    StillLifeBackupSerializer(
      exportService: JsonExportService(db),
      importService: ImportService(db),
    ),
    EnvelopeCipher(),
    aadContext: 'stilllife-backup/v1',
  );
  return PhotoBackupContainer(
    db: db,
    metadataRepo: repo,
    maxEntries: maxEntries ?? PhotoBackupContainer.defaultMaxEntries,
  );
}

Future<void> _seed(AppDatabase db, {bool withPhoto = true, bool withReceipt = true}) async {
  final now = DateTime(2026);
  await db.into(db.properties).insert(PropertiesCompanion.insert(
      id: 'p1', name: 'Home', createdAt: now, modifiedAt: now));
  await db.into(db.rooms).insert(RoomsCompanion.insert(
      id: 'r1', propertyId: 'p1', name: 'Room', createdAt: now, modifiedAt: now));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: 'c1', name: 'Cat', createdAt: now, modifiedAt: now));
  await db.into(db.items).insert(ItemsCompanion.insert(
      id: 'i1', name: 'Item', categoryId: 'c1', roomId: 'r1',
      createdAt: now, modifiedAt: now));
  if (withPhoto) {
    await db.into(db.photos).insert(PhotosCompanion.insert(
        id: 'ph1', itemId: 'i1', filePath: '',
        bytes: Value(_png), capturedAt: now, createdAt: now, modifiedAt: now));
  }
  if (withReceipt) {
    await db.into(db.receipts).insert(ReceiptsCompanion.insert(
        id: 'rc1', photoPath: '', itemId: const Value('i1'),
        photoBytes: Value(_receiptImg), createdAt: now));
  }
}

void main() {
  ensureSqlite3();

  group('estimate', () {
    test('counts photos + receipts and sums BLOB bytes', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await _seed(db);
      final est = await _container(db).estimate();
      expect(est.photoCount, 1);
      expect(est.receiptCount, 1);
      expect(est.totalBytes, _png.length + _receiptImg.length);
    });
  });

  group('export → import round-trip', () {
    test('carries metadata + photo + receipt BLOBs across a fresh DB',
        () async {
      final src = AppDatabase.memory();
      addTearDown(src.close);
      await _seed(src);

      final export = await _container(src).exportContainer(_key);
      expect(PhotoBackupContainer.isZipContainer(export.bytes), isTrue);
      expect(export.filename, endsWith('.ohbkz'));
      expect(export.skipped, isEmpty);

      final dst = AppDatabase.memory();
      addTearDown(dst.close);
      final result = await _container(dst).importContainer(export.bytes, _key);

      expect(result.wasContainer, isTrue);
      expect(result.photosRestored, 1);
      expect(result.receiptsRestored, 1);

      // Metadata row restored ...
      final items = await dst.select(dst.items).get();
      expect(items.map((i) => i.id), contains('i1'));
      // ... and the BLOBs re-attached by id.
      final photo = await (dst.select(dst.photos)
            ..where((p) => p.id.equals('ph1')))
          .getSingle();
      expect(photo.bytes, _png);
      final receipt = await (dst.select(dst.receipts)
            ..where((r) => r.id.equals('rc1')))
          .getSingle();
      expect(receipt.photoBytes, _receiptImg);
    });

    test('a bare .ohbk is detected and restored as metadata-only', () async {
      final src = AppDatabase.memory();
      addTearDown(src.close);
      await _seed(src);
      // Build a bare metadata .ohbk via the repo directly.
      final repo = BackupRepository(
        StillLifeBackupSerializer(
          exportService: JsonExportService(src),
          importService: ImportService(src),
        ),
        EnvelopeCipher(),
        aadContext: 'stilllife-backup/v1',
      );
      final ohbk = await repo.export(_key);
      expect(PhotoBackupContainer.isOhbk(ohbk), isTrue);

      final dst = AppDatabase.memory();
      addTearDown(dst.close);
      final result = await _container(dst).importContainer(ohbk, _key);
      expect(result.wasContainer, isFalse);
      final items = await dst.select(dst.items).get();
      expect(items.map((i) => i.id), contains('i1'));
    });
  });

  group('per-entry cap', () {
    test('a BLOB larger than the 10 MB ceiling is skipped and reported',
        () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final now = DateTime(2026);
      await _seed(db, withPhoto: false, withReceipt: false);
      // An oversized photo (skipped, never encrypted).
      await db.into(db.photos).insert(PhotosCompanion.insert(
          id: 'big', itemId: 'i1', filePath: '',
          bytes: Value(Uint8List(PhotoBackupContainer.maxBlobBytes + 1)),
          capturedAt: now, createdAt: now, modifiedAt: now));

      final export = await _container(db).exportContainer(_key);
      expect(export.skipped, contains('photo:big'));
    });
  });

  group('zip-bomb guards', () {
    test('rejects a container with too many entries', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await _seed(db);
      final export = await _container(db).exportContainer(_key);

      // Same bytes, but a container built to allow only 1 entry.
      final tiny = _container(db, maxEntries: 1);
      expect(
        () => tiny.importContainer(export.bytes, _key),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects an entry that declares an implausible size', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      // A hand-built zip whose single entry declares > maxEntryDeclaredBytes.
      final archive = Archive()
        ..addFile(ArchiveFile.noCompress(
          PhotoBackupContainer.metadataEntry,
          PhotoBackupContainer.defaultMaxEntryDeclaredBytes + 1,
          Uint8List(PhotoBackupContainer.defaultMaxEntryDeclaredBytes + 1),
        ));
      final zip = ZipEncoder().encodeBytes(archive);
      expect(
        () => _container(db).importContainer(zip, _key),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects a container missing metadata.ohbk', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('photos/x.ohbk', Uint8List(40)));
      final zip = ZipEncoder().encodeBytes(archive);
      expect(
        () => _container(db).importContainer(zip, _key),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });

  group('partial-blob tolerance', () {
    test('a photo row with no matching blob entry keeps null bytes (no crash)',
        () async {
      // Source has a photo WITHOUT bytes → metadata carries the row, container
      // carries no blob for it.
      final src = AppDatabase.memory();
      addTearDown(src.close);
      final now = DateTime(2026);
      await _seed(src, withPhoto: false, withReceipt: false);
      await src.into(src.photos).insert(PhotosCompanion.insert(
          id: 'noblob', itemId: 'i1', filePath: '',
          capturedAt: now, createdAt: now, modifiedAt: now));

      final export = await _container(src).exportContainer(_key);

      final dst = AppDatabase.memory();
      addTearDown(dst.close);
      final result = await _container(dst).importContainer(export.bytes, _key);
      expect(result.photosRestored, 0);
      final photo = await (dst.select(dst.photos)
            ..where((p) => p.id.equals('noblob')))
          .getSingle();
      expect(photo.bytes, isNull);
    });
  });

  group('cross-id rejection', () {
    test('a photo blob sealed for one id cannot be restored under another id',
        () async {
      // An attacker holding the .ohbkz (but not the key) cuts photo ph1's
      // sealed frame and pastes it onto a different id's filename. Because the
      // entry id is bound into the AEAD context, the frame no longer opens.
      final src = AppDatabase.memory();
      addTearDown(src.close);
      await _seed(src);
      final export = await _container(src).exportContainer(_key);

      final archive = ZipDecoder().decodeBytes(export.bytes);
      final meta = archive.files
          .firstWhere((f) => f.name == PhotoBackupContainer.metadataEntry);
      final photo = archive.files.firstWhere(
          (f) => f.name.startsWith(PhotoBackupContainer.photoDir));
      final swapped = Archive()
        ..addFile(ArchiveFile.bytes(
            PhotoBackupContainer.metadataEntry,
            Uint8List.fromList(meta.content)))
        ..addFile(ArchiveFile.bytes(
            '${PhotoBackupContainer.photoDir}other.ohbk',
            Uint8List.fromList(photo.content)));
      final zip = ZipEncoder().encodeBytes(swapped);

      final dst = AppDatabase.memory();
      addTearDown(dst.close);
      expect(
        () => _container(dst).importContainer(zip, _key),
        throwsA(isA<CryptoException>()),
      );
    });

    test('a photo blob cannot be restored as a receipt (path binding)',
        () async {
      // Even under the correct id, a photo frame must not open on the receipt
      // path — the entry kind is bound into the context too.
      final src = AppDatabase.memory();
      addTearDown(src.close);
      await _seed(src);
      final export = await _container(src).exportContainer(_key);

      final archive = ZipDecoder().decodeBytes(export.bytes);
      final meta = archive.files
          .firstWhere((f) => f.name == PhotoBackupContainer.metadataEntry);
      final photo = archive.files.firstWhere(
          (f) => f.name.startsWith(PhotoBackupContainer.photoDir));
      // Reuse the same id ('ph1') but move it to the receipts path.
      final crossed = Archive()
        ..addFile(ArchiveFile.bytes(
            PhotoBackupContainer.metadataEntry,
            Uint8List.fromList(meta.content)))
        ..addFile(ArchiveFile.bytes(
            '${PhotoBackupContainer.receiptDir}ph1.ohbk',
            Uint8List.fromList(photo.content)));
      final zip = ZipEncoder().encodeBytes(crossed);

      final dst = AppDatabase.memory();
      addTearDown(dst.close);
      expect(
        () => _container(dst).importContainer(zip, _key),
        throwsA(isA<CryptoException>()),
      );
    });
  });

  group('atomic restore', () {
    test('a corrupt photo entry aborts the whole restore — no half-state',
        () async {
      // A .ohbkz with valid metadata but one tampered photo frame must leave
      // the prior DB untouched: metadata must NOT commit while the blob fails
      // (§2.4 fail-closed, §2.5 single transaction).
      final src = AppDatabase.memory();
      addTearDown(src.close);
      await _seed(src);
      final export = await _container(src).exportContainer(_key);

      // Flip the MAC byte of the photo frame — metadata stays valid.
      final archive = ZipDecoder().decodeBytes(export.bytes);
      final rebuilt = Archive();
      for (final f in archive.files) {
        final content = Uint8List.fromList(f.content);
        if (f.name.startsWith(PhotoBackupContainer.photoDir)) {
          content[content.length - 1] ^= 0xFF;
        }
        rebuilt.addFile(ArchiveFile.bytes(f.name, content));
      }
      final zip = ZipEncoder().encodeBytes(rebuilt);

      // Destination already holds prior inventory that must survive intact.
      final dst = AppDatabase.memory();
      addTearDown(dst.close);
      final now = DateTime(2025);
      await dst.into(dst.properties).insert(PropertiesCompanion.insert(
          id: 'pExisting', name: 'Existing', createdAt: now, modifiedAt: now));

      await expectLater(
        () => _container(dst).importContainer(zip, _key),
        throwsA(isA<CryptoException>()),
      );

      // Nothing from the backup leaked in — the metadata merge rolled back.
      final props = await dst.select(dst.properties).get();
      expect(props.map((p) => p.id), ['pExisting']);
      final items = await dst.select(dst.items).get();
      expect(items, isEmpty);
    });
  });

  group('cross-context rejection', () {
    test('a photo-context blob cannot be opened as metadata', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      // Seal bytes under the PHOTO context, then plant it as metadata.ohbk.
      final photoBlob = await GhostBackup.export(
        _png, _key, EnvelopeCipher(),
        context: PhotoBackupContainer.photoContext,
      );
      final archive = Archive()
        ..addFile(
            ArchiveFile.bytes(PhotoBackupContainer.metadataEntry, photoBlob));
      final zip = ZipEncoder().encodeBytes(archive);

      expect(
        () => _container(db).importContainer(zip, _key),
        throwsA(isA<CryptoException>()),
      );
    });
  });
}

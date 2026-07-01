import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';
import 'package:still_life/services/backup/photo_backup_container.dart';
import 'package:still_life/services/backup/photo_restore_guard.dart';
import 'package:still_life/services/backup/still_life_backup_serializer.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';

import '../../../test_setup.dart';

final _key = Uint8List.fromList(List.generate(32, (i) => (i * 7) & 0xFF));
final _wrongKey = Uint8List.fromList(List.generate(32, (i) => (i * 11) & 0xFF));
final _oldPhotoBytes = Uint8List.fromList(const [9, 9, 9, 9]);
final _newPhotoBytes = Uint8List.fromList(const [1, 2, 3, 4, 5]);

/// An [InMemoryVaultStore] whose read-back always fails — simulates storage
/// that accepted the write but can't reproduce it (the exact "untested
/// backups don't count" case).
class _ReadBackFailingStore extends InMemoryVaultStore {
  @override
  Future<Uint8List?> read(String id) async => null;
}

/// An [InMemoryVaultStore] that flips one byte INSIDE the stored `.ohbkz`
/// snapshot's photo entry on read-back — same length, metadata entry intact.
/// Simulates bit-rot in storage: a length check + metadata-only decrypt
/// cannot see it, but the photo's AEAD tag no longer authenticates.
class _PhotoEntryCorruptingStore extends InMemoryVaultStore {
  @override
  Future<Uint8List?> read(String id) async {
    final bytes = await super.read(id);
    if (bytes == null) return null;
    final corrupted = Uint8List.fromList(bytes);
    // The zip local file header stores the entry name uncompressed; the
    // entry's (compressed) data follows it. Flip a byte a little past the
    // name so the flip lands inside the photo ciphertext, not the metadata.
    final name = 'photos/photo_old.ohbk'.codeUnits;
    final idx = _indexOf(corrupted, name);
    if (idx < 0) {
      throw StateError('test fixture: photo entry not found in snapshot');
    }
    corrupted[idx + name.length + 8] ^= 0xFF;
    return corrupted;
  }

  static int _indexOf(Uint8List haystack, List<int> needle) {
    outer:
    for (var i = 0; i + needle.length <= haystack.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }
}

BackupRepository _repo(AppDatabase db) => BackupRepository(
      StillLifeBackupSerializer(
        exportService: JsonExportService(db),
        importService: ImportService(db),
      ),
      EnvelopeCipher(),
      aadContext: 'stilllife-backup/v1',
    );

PhotoBackupContainer _container(AppDatabase db) =>
    PhotoBackupContainer(db: db, metadataRepo: _repo(db));

Future<void> _seed(
  AppDatabase db, {
  required String suffix,
  Uint8List? photoBytes,
}) async {
  final now = DateTime(2026);
  await db.into(db.properties).insert(PropertiesCompanion.insert(
      id: 'p_$suffix', name: 'Home', createdAt: now, modifiedAt: now));
  await db.into(db.rooms).insert(RoomsCompanion.insert(
      id: 'r_$suffix',
      propertyId: 'p_$suffix',
      name: 'Room',
      createdAt: now,
      modifiedAt: now));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: 'c_$suffix', name: 'Cat', createdAt: now, modifiedAt: now));
  await db.into(db.items).insert(ItemsCompanion.insert(
      id: 'item_$suffix',
      name: 'Item $suffix',
      categoryId: 'c_$suffix',
      roomId: 'r_$suffix',
      createdAt: now,
      modifiedAt: now));
  if (photoBytes != null) {
    await db.into(db.photos).insert(PhotosCompanion.insert(
        id: 'photo_$suffix',
        itemId: 'item_$suffix',
        filePath: '',
        bytes: Value(photoBytes),
        capturedAt: now,
        createdAt: now,
        modifiedAt: now));
  }
}

void main() {
  ensureSqlite3();

  late AppDatabase db; // the device being restored INTO ("old" data)
  late InMemoryVaultStore photoStore;
  late InMemoryVaultStore metadataStore;

  setUp(() async {
    db = AppDatabase.memory();
    photoStore = InMemoryVaultStore();
    metadataStore = InMemoryVaultStore();
    await _seed(db, suffix: 'old', photoBytes: _oldPhotoBytes);
  });

  tearDown(() => db.close());

  PhotoRestoreGuard guard({VaultStore? photos, VaultStore? metadata}) =>
      PhotoRestoreGuard(
        container: _container(db),
        metadataRepo: _repo(db),
        photoVault: BackupVault(photos ?? photoStore,
            appId: 'stilllife', keepN: 2, extension: 'ohbkz'),
        metadataVault:
            BackupVault(metadata ?? metadataStore, appId: 'stilllife'),
      );

  /// A photos-included `.ohbkz` made on a second device ("incoming").
  Future<Uint8List> incomingContainer() async {
    final src = AppDatabase.memory();
    addTearDown(src.close);
    await _seed(src, suffix: 'new', photoBytes: _newPhotoBytes);
    return (await _container(src).exportContainer(_key)).bytes;
  }

  group('photo-ful (.ohbkz) restore', () {
    test(
        'takes a MANDATORY photo-ful pre-restore snapshot into the photo '
        'vault, auto-pinned and verified, before the restore applies',
        () async {
      final incoming = await incomingContainer();
      final result = await guard().guardedImport(incoming, _key);
      expect(result.wasContainer, isTrue);

      // The restore itself applied…
      final items = await db.select(db.items).get();
      expect(items.map((i) => i.id), contains('item_new'));

      // …and the vault holds exactly one pre-restore .ohbkz snapshot.
      final entries = await photoStore.list();
      expect(entries, hasLength(1),
          reason: 'a photo-ful restore MUST leave a rollback snapshot');
      final entry = entries.single;
      expect(entry.label, VaultLabel.preRestore);
      expect(entry.autoPinned, isTrue);
      expect(entry.id, endsWith('.ohbkz'));

      // The snapshot captures the PRE-restore state, photos included:
      // importing it into a fresh device brings back the old item AND the
      // old photo bytes.
      final snapshotBytes = await photoStore.read(entry.id);
      final rollbackDb = AppDatabase.memory();
      addTearDown(rollbackDb.close);
      final rollback = PhotoBackupContainer(
        db: rollbackDb,
        metadataRepo: _repo(rollbackDb),
      );
      await rollback.importContainer(snapshotBytes!, _key);
      final rolledItems = await rollbackDb.select(rollbackDb.items).get();
      expect(rolledItems.map((i) => i.id), contains('item_old'));
      final rolledPhoto = await (rollbackDb.select(rollbackDb.photos)
            ..where((p) => p.id.equals('photo_old')))
          .getSingle();
      expect(rolledPhoto.bytes, _oldPhotoBytes,
          reason: 'the rollback must cover the photos the restore overwrites');
    });

    test('wrong key: throws CryptoException and takes NO snapshot', () async {
      final incoming = await incomingContainer();
      await expectLater(
        guard().guardedImport(incoming, _wrongKey),
        throwsA(isA<CryptoException>()),
      );
      expect(await photoStore.list(), isEmpty,
          reason: 'wrong-key attempts must not spam pre-restore snapshots');
      final items = await db.select(db.items).get();
      expect(items.map((i) => i.id), isNot(contains('item_new')));
    });

    test('snapshot save failure ABORTS the restore fail-closed', () async {
      final incoming = await incomingContainer();
      photoStore.failNextPut = true;

      await expectLater(
        guard().guardedImport(incoming, _key),
        throwsA(isA<PhotoSnapshotException>()),
      );

      // Nothing changed: old data intact, new data absent.
      final items = await db.select(db.items).get();
      expect(items.map((i) => i.id), contains('item_old'));
      expect(items.map((i) => i.id), isNot(contains('item_new')));
      final photo = await (db.select(db.photos)
            ..where((p) => p.id.equals('photo_old')))
          .getSingle();
      expect(photo.bytes, _oldPhotoBytes);
    });

    test('snapshot read-back failure ABORTS the restore fail-closed',
        () async {
      final incoming = await incomingContainer();
      await expectLater(
        guard(photos: _ReadBackFailingStore()).guardedImport(incoming, _key),
        throwsA(isA<PhotoSnapshotException>()),
      );
      final items = await db.select(db.items).get();
      expect(items.map((i) => i.id), isNot(contains('item_new')));
    });

    test(
        'a snapshot whose PHOTO entry corrupts in storage fails read-back '
        'verification — every entry is authenticated, not just metadata',
        () async {
      final incoming = await incomingContainer();
      await expectLater(
        guard(photos: _PhotoEntryCorruptingStore())
            .guardedImport(incoming, _key),
        throwsA(isA<PhotoSnapshotException>()),
        reason: 'a rollback with an unopenable photo is not a rollback — '
            '"verified by read-back" must cover the AEAD tag of every entry',
      );
      final items = await db.select(db.items).get();
      expect(items.map((i) => i.id), isNot(contains('item_new')),
          reason: 'fail-closed: no restore on an unverified snapshot');
    });
  });

  group('snapshotKey (the post-restore-identity invariant)', () {
    // _wrongKey stands in for the DEVICE's own key here: a foreign backup
    // opens under the incoming _key, but the rollback snapshot must open
    // under the device credentials or it is rollback theater.
    test(
        '.ohbkz: the snapshot seals and verifies under snapshotKey, '
        'not the incoming key', () async {
      final incoming = await incomingContainer();
      await guard().guardedImport(incoming, _key, snapshotKey: _wrongKey);

      final entry = (await photoStore.list()).single;
      final snapshotBytes = await photoStore.read(entry.id);

      final rollbackDb = AppDatabase.memory();
      addTearDown(rollbackDb.close);
      final rollback = PhotoBackupContainer(
        db: rollbackDb,
        metadataRepo: _repo(rollbackDb),
      );
      await rollback.importContainer(snapshotBytes!, _wrongKey);
      final rolled = await rollbackDb.select(rollbackDb.items).get();
      expect(rolled.map((i) => i.id), contains('item_old'),
          reason: 'the snapshot must open under the device key');

      final otherDb = AppDatabase.memory();
      addTearDown(otherDb.close);
      await expectLater(
        PhotoBackupContainer(db: otherDb, metadataRepo: _repo(otherDb))
            .importContainer(snapshotBytes, _key),
        throwsA(isA<CryptoException>()),
        reason: 'the snapshot must NOT be sealed under the incoming key',
      );
    });

    test('bare .ohbk: the metadata snapshot seals under snapshotKey',
        () async {
      final src = AppDatabase.memory();
      addTearDown(src.close);
      await _seed(src, suffix: 'new');
      final bareOhbk = await _repo(src).export(_key);

      await guard().guardedImport(bareOhbk, _key, snapshotKey: _wrongKey);

      final entry = (await metadataStore.list()).single;
      final snapshotBytes = await metadataStore.read(entry.id);
      // Opens under the device key…
      await _repo(db).open(snapshotBytes!, _wrongKey);
      // …and not under the incoming key.
      await expectLater(
        _repo(db).open(snapshotBytes, _key),
        throwsA(isA<CryptoException>()),
      );
    });
  });

  group('bare .ohbk through the photo path', () {
    test('takes a verified metadata pre-restore snapshot into the main vault',
        () async {
      final src = AppDatabase.memory();
      addTearDown(src.close);
      await _seed(src, suffix: 'new');
      final bareOhbk = await _repo(src).export(_key);

      final result = await guard().guardedImport(bareOhbk, _key);
      expect(result.wasContainer, isFalse);

      final items = await db.select(db.items).get();
      expect(items.map((i) => i.id), contains('item_new'));

      final entries = await metadataStore.list();
      expect(entries, hasLength(1),
          reason: 'even the metadata-only path must leave a rollback');
      expect(entries.single.label, VaultLabel.preRestore);
      expect(entries.single.id, endsWith('.ohbk'));
      expect(await photoStore.list(), isEmpty,
          reason: 'metadata restores must not bloat the photo vault (§3)');
    });
  });

  test(
      'corrupt photo entry AFTER a good metadata check throws '
      'BackupCorruptException, not CryptoException (wrong-key means wrong '
      'key, damage means damage)', () async {
    // Metadata sealed under _key opens fine; the photo entry is validly
    // sealed under a DIFFERENT key → decrypt-first passes, the import's
    // per-entry decrypt fails.
    final good = await incomingContainer();
    final archive = ZipDecoder().decodeBytes(good);
    final bad = Archive();
    for (final f in archive.files) {
      if (f.name == 'photos/photo_new.ohbk') {
        final sealed = await GhostBackup.export(
          Uint8List.fromList(const [6, 6, 6]),
          _wrongKey,
          EnvelopeCipher(),
          context: 'stilllife-photo/v1|photo|photo_new',
        );
        bad.addFile(ArchiveFile.bytes(f.name, sealed));
      } else {
        bad.addFile(ArchiveFile.bytes(f.name, Uint8List.fromList(f.content)));
      }
    }
    final tampered = ZipEncoder().encodeBytes(bad);

    await expectLater(
      guard().guardedImport(tampered, _key),
      throwsA(isA<BackupCorruptException>()),
    );
    // The single-transaction import rolled back — nothing half-restored.
    final items = await db.select(db.items).get();
    expect(items.map((i) => i.id), isNot(contains('item_new')));
    expect(items.map((i) => i.id), contains('item_old'));
  });

  test('junk bytes: BackupFormatException, no snapshot anywhere', () async {
    await expectLater(
      guard().guardedImport(
          Uint8List.fromList(List.filled(64, 0x42)), _key),
      throwsA(isA<BackupFormatException>()),
    );
    expect(await photoStore.list(), isEmpty);
    expect(await metadataStore.list(), isEmpty);
  });
}

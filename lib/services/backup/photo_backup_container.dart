import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../database/database.dart';

/// Rough size of a full photos-included backup, for the "Include photos"
/// confirmation.
class BlobBackupEstimate {
  final int photoCount;
  final int receiptCount;

  /// Sum of the plaintext BLOB lengths (pre-encryption, pre-zip). The container
  /// is a little larger (AEAD + zip overhead) but this is the honest headline.
  final int totalBytes;

  const BlobBackupEstimate({
    required this.photoCount,
    required this.receiptCount,
    required this.totalBytes,
  });

  int get blobCount => photoCount + receiptCount;
}

/// Result of exporting a `.ohbkz` container.
class ContainerExportResult {
  final Uint8List bytes;
  final String filename;

  /// Entry keys (`photo:<id>` / `receipt:<id>`) skipped because a single BLOB
  /// exceeded the 10 MB OHBK ceiling. Surfaced to the user, never silent.
  final List<String> skipped;

  const ContainerExportResult({
    required this.bytes,
    required this.filename,
    required this.skipped,
  });
}

/// Result of importing a backup (bare `.ohbk` or `.ohbkz` container).
class ContainerImportResult {
  final bool wasContainer;
  final int photosRestored;
  final int receiptsRestored;

  const ContainerImportResult({
    required this.wasContainer,
    required this.photosRestored,
    required this.receiptsRestored,
  });
}

/// The `.ohbkz` photos-included backup container (SANCTUARY-BRIEF §4.W3 — the
/// night's chunked-media format pilot).
///
/// A `.ohbkz` is a ZIP holding:
/// ```
///   metadata.ohbk           # the inventory metadata (context stilllife-backup/v1)
///   photos/<photoId>.ohbk   # each full-size photo BLOB (context stilllife-photo/v1)
///   receipts/<receiptId>.ohbk
/// ```
/// Every entry is an individual OHBK blob (≤ 10 MB) — the container never
/// exceeds sanctuary's single-blob format; large media is chunked across
/// entries instead. Photo thumbnails are best-effort/derived and are NOT
/// backed up (they regenerate); the full-resolution bytes are.
///
/// The metadata entry is produced/consumed by the same [BackupRepository] the
/// bare-`.ohbk` flow uses, so the two formats share one code path for the
/// inventory. Only the zip assembly, magic-byte detection, and bomb guards are
/// new here.
class PhotoBackupContainer {
  final AppDatabase _db;
  final BackupRepository _metadataRepo;
  final EnvelopeCipher _cipher;

  /// Base AEAD context for individual photo/receipt BLOB entries — distinct
  /// from the metadata context so a photo blob can never be opened as metadata.
  ///
  /// The per-entry context additionally binds the entry KIND and ID (see
  /// [_entryContext]) so a sealed frame only opens against the exact row it was
  /// sealed for. Without that binding every blob shares one context, letting an
  /// attacker who holds the container (but not the key) swap/duplicate frames
  /// between rows undetected — the zip filenames are unauthenticated.
  static const String photoContext = 'stilllife-photo/v1';

  /// Per-entry AEAD context binding the entry kind + id into the AAD, e.g.
  /// `stilllife-photo/v1|photo|<id>` / `stilllife-photo/v1|receipt|<id>`.
  static String _entryContext(String kind, String id) =>
      '$photoContext|$kind|$id';

  static const String metadataEntry = 'metadata.ohbk';
  static const String photoDir = 'photos/';
  static const String receiptDir = 'receipts/';

  /// Per-entry plaintext ceiling — matches GhostBackup's 10 MB blob cap (a
  /// 34-byte header/nonce/mac lives on top). Larger single BLOBs are skipped.
  static const int maxBlobBytes = 10 * 1024 * 1024 - 34;

  /// Zip-bomb guards (mirroring the limits pattern PT uses): a ceiling on entry
  /// count and on total declared uncompressed size, enforced before any entry
  /// is decompressed. Overridable (tests set tiny ceilings).
  static const int defaultMaxEntries = 50000;
  static const int defaultMaxTotalUncompressedBytes =
      2 * 1024 * 1024 * 1024; // 2 GB

  /// A single entry may not declare more than one over-cap blob's worth of
  /// uncompressed bytes (blob ceiling + a small header allowance).
  static const int defaultMaxEntryDeclaredBytes = 12 * 1024 * 1024;

  final int maxEntries;
  final int maxTotalUncompressedBytes;
  final int maxEntryDeclaredBytes;

  PhotoBackupContainer({
    required AppDatabase db,
    required BackupRepository metadataRepo,
    EnvelopeCipher? cipher,
    this.maxEntries = defaultMaxEntries,
    this.maxTotalUncompressedBytes = defaultMaxTotalUncompressedBytes,
    this.maxEntryDeclaredBytes = defaultMaxEntryDeclaredBytes,
  }) : _db = db,
       _metadataRepo = metadataRepo,
       _cipher = cipher ?? EnvelopeCipher();

  static bool isZipContainer(List<int> bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      bytes[2] == 0x03 &&
      bytes[3] == 0x04; // "PK\x03\x04"

  static bool isOhbk(List<int> bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x4F &&
      bytes[1] == 0x48 &&
      bytes[2] == 0x42 &&
      bytes[3] == 0x4B; // "OHBK"

  /// Estimates the size and count of a photos-included backup without loading
  /// any BLOB into memory.
  Future<BlobBackupEstimate> estimate() async {
    final row = await _db
        .customSelect(
          'SELECT '
          "(SELECT COUNT(*) FROM photos WHERE bytes IS NOT NULL AND is_deleted = 0) AS pc, "
          "(SELECT COALESCE(SUM(LENGTH(bytes)),0) FROM photos WHERE bytes IS NOT NULL AND is_deleted = 0) AS pb, "
          "(SELECT COUNT(*) FROM receipts WHERE photo_bytes IS NOT NULL AND is_deleted = 0) AS rc, "
          "(SELECT COALESCE(SUM(LENGTH(photo_bytes)),0) FROM receipts WHERE photo_bytes IS NOT NULL AND is_deleted = 0) AS rb",
        )
        .getSingle();
    final pc = row.read<int>('pc');
    final pb = row.read<int>('pb');
    final rc = row.read<int>('rc');
    final rb = row.read<int>('rb');
    return BlobBackupEstimate(
      photoCount: pc,
      receiptCount: rc,
      totalBytes: pb + rb,
    );
  }

  /// Builds a `.ohbkz` container encrypted under [key].
  Future<ContainerExportResult> exportContainer(Uint8List key) async {
    final archive = Archive();
    final skipped = <String>[];

    // Read a consistent snapshot — the metadata blob plus every photo/receipt
    // row — inside one transaction, so a concurrent LAN-sync import can't tear
    // the container (e.g. a photo whose parent item is missing from metadata,
    // or vice versa). The CPU-heavy per-blob AEAD sealing runs AFTER the
    // transaction closes, so the read lock is held only for the reads, not the
    // crypto loop.
    final Uint8List metadata;
    final List<Photo> photos;
    final List<Receipt> receipts;
    (metadata, photos, receipts) = await _db.transaction(() async {
      // Metadata via the shared repository (context stilllife-backup/v1).
      final m = await _metadataRepo.export(key);
      final ph = await (_db.select(_db.photos)
            ..where((p) => p.bytes.isNotNull() & p.isDeleted.equals(false)))
          .get();
      final rc = await (_db.select(_db.receipts)
            ..where((r) => r.photoBytes.isNotNull() & r.isDeleted.equals(false)))
          .get();
      return (m, ph, rc);
    });
    archive.addFile(ArchiveFile.bytes(metadataEntry, metadata));

    for (final p in photos) {
      final blob = p.bytes;
      if (blob == null) continue;
      if (blob.length > maxBlobBytes) {
        skipped.add('photo:${p.id}');
        continue;
      }
      final sealed = await GhostBackup.export(blob, key, _cipher,
          context: _entryContext('photo', p.id));
      archive.addFile(ArchiveFile.bytes('$photoDir${p.id}.ohbk', sealed));
    }

    for (final r in receipts) {
      final blob = r.photoBytes;
      if (blob == null) continue;
      if (blob.length > maxBlobBytes) {
        skipped.add('receipt:${r.id}');
        continue;
      }
      final sealed = await GhostBackup.export(blob, key, _cipher,
          context: _entryContext('receipt', r.id));
      archive.addFile(ArchiveFile.bytes('$receiptDir${r.id}.ohbk', sealed));
    }

    final zip = ZipEncoder().encodeBytes(archive);
    final date = _today();
    return ContainerExportResult(
      bytes: zip,
      filename: 'stilllife-backup-$date.ohbkz',
      skipped: skipped,
    );
  }

  /// Imports a backup: a bare `.ohbk` (metadata only) or a `.ohbkz` container.
  ///
  /// Detects the format by magic bytes. For a container: enforces the bomb
  /// guards, restores metadata first, then decrypts each BLOB and re-attaches
  /// it to its row by id. A photo row with no matching blob entry simply keeps
  /// null bytes; a blob entry whose id matches no row is a no-op — neither
  /// crashes. Throws [BackupFormatException] / [CryptoException] on a
  /// malformed, oversized, or wrong-key/context payload (fail closed).
  Future<ContainerImportResult> importContainer(
    Uint8List data,
    Uint8List key,
  ) async {
    if (isOhbk(data)) {
      await _metadataRepo.restore(data, key);
      return const ContainerImportResult(
        wasContainer: false,
        photosRestored: 0,
        receiptsRestored: 0,
      );
    }
    if (!isZipContainer(data)) {
      throw BackupFormatException('Not a Still Life backup file.');
    }

    final archive = ZipDecoder().decodeBytes(data);

    // Bomb guards — declared sizes only, before any entry is decompressed.
    if (archive.files.length > maxEntries) {
      throw BackupFormatException(
        'Backup has too many entries (${archive.files.length}).',
      );
    }
    var totalDeclared = 0;
    for (final f in archive.files) {
      if (f.size < 0 || f.size > maxEntryDeclaredBytes) {
        throw BackupFormatException(
          'Backup entry ${f.name} declares an implausible size (${f.size}).',
        );
      }
      totalDeclared += f.size;
      if (totalDeclared > maxTotalUncompressedBytes) {
        throw BackupFormatException('Backup is too large to restore safely.');
      }
    }

    final metaFile =
        archive.files.firstWhereOrNull((f) => f.name == metadataEntry);
    if (metaFile == null) {
      throw BackupFormatException('Backup is missing $metadataEntry.');
    }

    // Apply the metadata merge AND re-attach every BLOB inside ONE
    // transaction, so a corrupt/tampered photo entry (a CryptoException mid
    // loop) rolls the metadata merge back too — never a half-restored DB with
    // committed records but missing images (§2.4 fail-closed, §2.5 single
    // transaction). The metadata restore opens its own transaction, which
    // drift nests as a savepoint inside this outer one, so an outer rollback
    // undoes it as well. Each blob is decrypted then written one at a time, so
    // a large photo set never has to be held fully in memory at once.
    var photosRestored = 0;
    var receiptsRestored = 0;
    await _db.transaction(() async {
      await _metadataRepo.restore(
        Uint8List.fromList(metaFile.content),
        key,
      );
      for (final f in archive.files) {
        if (f.name == metadataEntry) continue;
        if (f.name.startsWith(photoDir)) {
          final id = _idFromEntry(f.name, photoDir);
          if (id == null) continue;
          final plaintext = await GhostBackup.import(
            Uint8List.fromList(f.content),
            key,
            _cipher,
            context: _entryContext('photo', id),
          );
          final n = await (_db.update(_db.photos)
                ..where((p) => p.id.equals(id)))
              .write(PhotosCompanion(bytes: Value(plaintext)));
          photosRestored += n;
        } else if (f.name.startsWith(receiptDir)) {
          final id = _idFromEntry(f.name, receiptDir);
          if (id == null) continue;
          final plaintext = await GhostBackup.import(
            Uint8List.fromList(f.content),
            key,
            _cipher,
            context: _entryContext('receipt', id),
          );
          final n = await (_db.update(_db.receipts)
                ..where((r) => r.id.equals(id)))
              .write(ReceiptsCompanion(photoBytes: Value(plaintext)));
          receiptsRestored += n;
        }
        // Unknown entries are ignored.
      }
    });

    return ContainerImportResult(
      wasContainer: true,
      photosRestored: photosRestored,
      receiptsRestored: receiptsRestored,
    );
  }

  /// Decrypt-authenticates EVERY entry of a backup without writing anything:
  /// the metadata entry through the shared repository, each photo/receipt
  /// blob through its bound per-entry AEAD context. Plaintexts are decrypted
  /// one entry at a time and discarded — nothing is buffered.
  ///
  /// This is the read-back verification the restore guard rests on:
  /// length-comparing the container and opening only its metadata would
  /// certify a "verified" rollback whose photo tags no longer authenticate.
  /// Throws [CryptoException] on any tampered/corrupt entry and
  /// [BackupFormatException] on a malformed container.
  Future<void> verifyContainer(Uint8List data, Uint8List key) async {
    if (isOhbk(data)) {
      // A bare metadata blob: opening it authenticates the whole payload.
      await _metadataRepo.open(data, key);
      return;
    }
    if (!isZipContainer(data)) {
      throw BackupFormatException('Not a Still Life backup file.');
    }

    final archive = ZipDecoder().decodeBytes(data);
    final metaFile =
        archive.files.firstWhereOrNull((f) => f.name == metadataEntry);
    if (metaFile == null) {
      throw BackupFormatException('Backup is missing $metadataEntry.');
    }
    await _metadataRepo.open(Uint8List.fromList(metaFile.content), key);

    for (final f in archive.files) {
      if (f.name == metadataEntry) continue;
      final String kind;
      final String? id;
      if (f.name.startsWith(photoDir)) {
        kind = 'photo';
        id = _idFromEntry(f.name, photoDir);
      } else if (f.name.startsWith(receiptDir)) {
        kind = 'receipt';
        id = _idFromEntry(f.name, receiptDir);
      } else {
        continue; // Unknown entries are ignored, matching importContainer.
      }
      if (id == null) continue;
      await GhostBackup.import(
        Uint8List.fromList(f.content),
        key,
        _cipher,
        context: _entryContext(kind, id),
      );
    }
  }

  /// Extracts `<id>` from `photos/<id>.ohbk`. Returns null for a nested path
  /// or a missing `.ohbk` suffix (the id is only ever used as a row-id match,
  /// never a filesystem path, but reject odd shapes defensively).
  static String? _idFromEntry(String name, String dir) {
    final rest = name.substring(dir.length);
    if (rest.contains('/') || !rest.endsWith('.ohbk')) return null;
    final id = rest.substring(0, rest.length - '.ohbk'.length);
    return id.isEmpty ? null : id;
  }

  static String _today() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}

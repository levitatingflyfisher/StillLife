import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import 'photo_backup_container.dart';

/// Thrown when the mandatory pre-restore snapshot could not be taken or did
/// not verify by read-back: the restore MUST NOT proceed (fail-closed,
/// BACKUP_RETENTION_SPEC §2.B). Carries the underlying [cause] for logs;
/// user copy is the honest "nothing was changed" dialog.
class PhotoSnapshotException implements Exception {
  final Object? cause;

  const PhotoSnapshotException([this.cause]);

  @override
  String toString() => 'PhotoSnapshotException(cause: $cause)';
}

/// Thrown when the backup's metadata already opened under the key (so the
/// key is RIGHT) but a later entry failed to decrypt: the file is damaged
/// or tampered, emphatically not a wrong-key case. Kept distinct from
/// [CryptoException] so the UI never sends the user hunting for "a
/// different set of words" that cannot exist. Carries the underlying
/// [cause] for logs.
class BackupCorruptException implements Exception {
  final Object? cause;

  const BackupCorruptException([this.cause]);

  @override
  String toString() => 'BackupCorruptException(cause: $cause)';
}

/// The guarded photo-backup restore path (BACKUP_RETENTION_SPEC §3 + §8).
///
/// The `.ohbkz` flow historically bypassed `BackupController` entirely — no
/// pre-restore snapshot, no vault, a dialog that said "cannot be undone" and
/// meant it. This guard wraps [PhotoBackupContainer.importContainer] with the
/// same promise the metadata flow makes.
class PhotoRestoreGuard {
  final PhotoBackupContainer container;

  /// The metadata `.ohbk` repository — used both to verify snapshots by
  /// read-back and to take the metadata-scoped snapshot for bare `.ohbk`
  /// restores arriving through this path.
  final BackupRepository metadataRepo;

  /// The SECOND vault (scope 'stilllife-photos', keep-N 2, `.ohbkz`) holding
  /// photo-ful snapshots — separate from the metadata vault because photos
  /// are MBs–GBs (§3's StillLife exception).
  final BackupVault photoVault;

  /// The app's main metadata vault (scope 'stilllife', `.ohbk`).
  final BackupVault metadataVault;

  const PhotoRestoreGuard({
    required this.container,
    required this.metadataRepo,
    required this.photoVault,
    required this.metadataVault,
  });

  /// Imports a backup with the mandatory fail-closed pre-restore snapshot.
  ///
  /// Three phases:
  /// 1. **Decrypt-first** (the package's two-phase precedent): prove [key]
  ///    opens this backup's metadata BEFORE anything is vaulted, so
  ///    wrong-key attempts never spam pre-restore snapshots.
  /// 2. **Mandatory snapshot**, scoped to what the restore will overwrite
  ///    (§3's StillLife exception): a photo-ful `.ohbkz` of current data
  ///    into [photoVault] when the incoming file is a container, a metadata
  ///    `.ohbk` into [metadataVault] when it's bare. Saved as
  ///    [VaultLabel.preRestore] (auto-pinned by the vault) and VERIFIED by
  ///    read-back; any failure throws [PhotoSnapshotException] and NOTHING
  ///    is restored (fail-closed, §2.B).
  /// 3. The restore itself — [PhotoBackupContainer.importContainer]'s
  ///    single transaction.
  ///
  /// [snapshotKey] seals (and verifies) the pre-restore snapshot. The
  /// invariant it exists to hold: **the snapshot is always openable by the
  /// post-restore device identity.** When a backup made with foreign words
  /// is restored onto a device that has its own identity, [key] is the
  /// backup's key but the rollback must open under the DEVICE's key —
  /// sealed under the incoming key it would be rollback theater. Callers
  /// pass the device's stored key when one exists; when the device has no
  /// identity it defaults to [key] (and the restore flow then adopts that
  /// phrase as the device identity, keeping the invariant).
  Future<ContainerImportResult> guardedImport(
    Uint8List data,
    Uint8List key, {
    Uint8List? snapshotKey,
  }) async {
    final sealKey = snapshotKey ?? key;
    await _openMetadataEntry(data, key);

    if (PhotoBackupContainer.isZipContainer(data)) {
      await _takeVerifiedSnapshot(
        vault: photoVault,
        exportBytes: () async =>
            (await container.exportContainer(sealKey)).bytes,
        // EVERY entry of the read-back snapshot is decrypt-authenticated —
        // a metadata-only check would certify a rollback whose photo AEAD
        // tags no longer open (bit-rot in the vault).
        verify: (bytes) => container.verifyContainer(bytes, sealKey),
      );
    } else {
      await _takeVerifiedSnapshot(
        vault: metadataVault,
        exportBytes: () => metadataRepo.export(sealKey),
        verify: (bytes) => metadataRepo.open(bytes, sealKey),
      );
    }

    try {
      return await container.importContainer(data, key);
    } on CryptoException catch (e) {
      // The decrypt-first phase proved [key] opens this backup's metadata,
      // so a crypto failure during the import itself is a damaged/tampered
      // entry — surface it as corruption, never as a wrong key. (The
      // import's single transaction has already rolled back.)
      throw BackupCorruptException(e);
    }
  }

  /// Decrypts (only) the metadata of [data] under [key] — a dry-run that
  /// never writes. Throws [CryptoException] for a wrong key/tampered blob
  /// and [BackupFormatException] for something that isn't a Still Life
  /// backup at all.
  Future<void> _openMetadataEntry(Uint8List data, Uint8List key) async {
    if (PhotoBackupContainer.isOhbk(data)) {
      await metadataRepo.open(data, key);
      return;
    }
    if (!PhotoBackupContainer.isZipContainer(data)) {
      throw BackupFormatException('Not a Still Life backup file.');
    }
    final archive = ZipDecoder().decodeBytes(data);
    final meta = archive.files
        .firstWhereOrNull((f) => f.name == PhotoBackupContainer.metadataEntry);
    if (meta == null) {
      throw BackupFormatException(
          'Backup is missing ${PhotoBackupContainer.metadataEntry}.');
    }
    // Light bomb guard for the one entry this dry-run decompresses; the
    // full guards still run inside importContainer before anything else.
    if (meta.size < 0 || meta.size > container.maxEntryDeclaredBytes) {
      throw BackupFormatException(
          'Backup metadata declares an implausible size (${meta.size}).');
    }
    await metadataRepo.open(Uint8List.fromList(meta.content), key);
  }

  /// Saves [exportBytes]'s output to [vault] as the auto-pinned pre-restore
  /// snapshot, then PROVES it: read the stored bytes back and [verify] they
  /// still open under the same key ("untested backups don't count" applies
  /// doubly to the rollback the whole promise rests on). Any failure —
  /// export, save, read-back, verify — becomes [PhotoSnapshotException].
  Future<void> _takeVerifiedSnapshot({
    required BackupVault vault,
    required Future<Uint8List> Function() exportBytes,
    required Future<void> Function(Uint8List bytes) verify,
  }) async {
    try {
      final bytes = await exportBytes();
      final entry = await vault.save(bytes, label: VaultLabel.preRestore);
      final readBack = await vault.read(entry.id);
      if (readBack == null || readBack.length != bytes.length) {
        throw StateError('pre-restore snapshot did not read back');
      }
      await verify(readBack);
    } on Object catch (e) {
      throw PhotoSnapshotException(e);
    }
  }
}

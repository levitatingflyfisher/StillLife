import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../../../services/backup/photo_backup_container.dart';
import '../../../services/backup/photo_restore_guard.dart';
import '../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../photo_backup_providers.dart';

/// The photo-backup restore orchestration once the backup bytes are in hand:
/// confirm → key resolution (device key, else recovery words) → guarded
/// import. Split from the file pick so widget tests can drive it without the
/// file_picker plugin (the `BackupFlow.restorePickedBlob` precedent).
class PhotoRestoreFlow {
  const PhotoRestoreFlow();

  /// Honest copy for [BackupCorruptException]: the words were right, the
  /// file is not. The import runs in one transaction, so nothing changed.
  static const _damagedBackupMessage =
      'This backup file is damaged and could not be restored. '
      'Nothing on this device was changed.';

  /// Runs the full restore flow for picked/vaulted backup [bytes]
  /// (`.ohbkz` container or bare `.ohbk`), always through
  /// [PhotoRestoreGuard] — never straight to `importContainer`.
  ///
  /// [skipConfirm] is for callers that have ALREADY shown their own confirm
  /// dialog (the snapshots section): one action gets one honest dialog, not
  /// two stacked ones with contradicting copy.
  Future<void> restorePicked(
    BuildContext context,
    WidgetRef ref,
    Uint8List bytes, {
    bool skipConfirm = false,
  }) async {
    if (!skipConfirm) {
      // Sniff the bytes FIRST: a `.ohbkz` container gets a photos-included
      // snapshot, a bare `.ohbk` a records-only one — the dialog must
      // promise the snapshot the guard will actually take.
      final confirm = await _confirmMerge(
        context,
        photosIncluded: PhotoBackupContainer.isZipContainer(bytes),
      );
      if (confirm != true || !context.mounted) return;
    }

    final guard = ref.read(photoRestoreGuardProvider);

    // Prefer this device's key; fall back to the recovery words if there is
    // none (a fresh install restoring someone's backup). When the words are
    // typed, the RAW phrase is kept alongside the derived key so a
    // successful restore can adopt it as the device identity.
    final deviceKey =
        (await ref.read(authNotifierProvider.future)).masterEncryptionKey;
    if (!context.mounted) return;
    var key = deviceKey;
    String? adoptPhrase;
    if (key == null) {
      final entered = await _keyFromPhrase(context, ref);
      if (entered == null || !context.mounted) return;
      key = entered.key;
      adoptPhrase = entered.phrase;
    }

    try {
      await guard.guardedImport(bytes, key);
      await _maybeAdoptPhrase(ref, adoptPhrase);
      _afterRestore(ref);
      if (context.mounted) _snack(context, 'Backup restored.');
    } on BackupCorruptException {
      // The key opened the metadata but an entry failed to decrypt: the
      // FILE is damaged — asking for different words would be a lie.
      if (context.mounted) _snack(context, _damagedBackupMessage);
    } on CryptoException {
      // Wrong key — the guard decrypts BEFORE snapshotting, so nothing was
      // vaulted; offer the words the backup was made with.
      if (!context.mounted) return;
      final entered = await _keyFromPhrase(context, ref, wrongKey: true);
      if (entered == null || !context.mounted) return;
      try {
        // The backup's key opens the incoming data, but the pre-restore
        // snapshot must stay openable by THIS device's identity — seal it
        // under the device key when one exists (when there is none the
        // entered phrase becomes the device identity via adoption below,
        // so the invariant holds either way).
        await guard.guardedImport(bytes, entered.key,
            snapshotKey: deviceKey ?? entered.key);
        await _maybeAdoptPhrase(ref, entered.phrase);
        _afterRestore(ref);
        if (context.mounted) _snack(context, 'Backup restored.');
      } on BackupCorruptException {
        if (context.mounted) _snack(context, _damagedBackupMessage);
      } on CryptoException {
        if (context.mounted) {
          _snack(context, "Those words didn't unlock this backup.");
        }
      } on PhotoSnapshotException {
        if (context.mounted) await _snapshotFailedDialog(context);
      } catch (e) {
        if (context.mounted) _snack(context, 'Restore failed: $e');
      }
    } on PhotoSnapshotException {
      // Fail-closed refusal (§2.B): nothing was restored — say so honestly.
      if (context.mounted) await _snapshotFailedDialog(context);
    } catch (e) {
      if (context.mounted) _snack(context, 'Restore failed: $e');
    }
  }

  /// After a successful phrase restore, persist the typed phrase as this
  /// device's identity — mirroring `BackupController._maybeAdoptPhrase` in
  /// sanctuary_backup_ui exactly: typing the words to restore IS proof of
  /// possession, so acknowledgement is recorded too. Re-checks the KEYSTORE
  /// (not cached provider state — another flow could have minted an identity
  /// meanwhile): an existing mnemonic is never overwritten. Best-effort: the
  /// restore itself already succeeded, so a failed adoption only leaves the
  /// device keyless, exactly as before.
  Future<void> _maybeAdoptPhrase(WidgetRef ref, String? phrase) async {
    if (phrase == null) return;
    try {
      final store = ref.read(secureKeyStoreProvider);
      if (await store.readMnemonic() != null) return;
      await store.writeMnemonic(phrase);
      await store.writeSeedAcknowledged();
      ref.invalidate(authNotifierProvider);
    } on Object {
      // Recorded nowhere: adoption is best-effort by design.
    }
  }

  /// The honest refusal dialog: the mandatory snapshot could not be taken or
  /// verified, so the restore never started and nothing changed.
  Future<void> _snapshotFailedDialog(BuildContext context) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text("Couldn't save a safety snapshot"),
          content: const Text(
            'Still Life could not save a verified snapshot of your current '
            'data, so the restore was not started. Nothing on this device '
            'was changed. This can happen when storage is full — free some '
            'space and try again.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

  /// Prompts for the recovery words and derives the key. Returns BOTH the
  /// derived key and the raw phrase — the caller needs the phrase to adopt
  /// it as the device identity after a successful fresh-install restore.
  Future<({Uint8List key, String phrase})?> _keyFromPhrase(
    BuildContext context,
    WidgetRef ref, {
    bool wrongKey = false,
  }) async {
    final phrase = await PhraseEntryDialog.show(
      context,
      title: wrongKey
          ? "Enter the backup's recovery words"
          : 'Enter your recovery words',
      body: wrongKey
          ? 'This backup was made with a different set of words than this '
              'device has. Enter the 12 words from when it was created.'
          : 'Enter the 12 recovery words to unlock this backup.',
    );
    if (phrase == null) return null;
    try {
      final keys = await ref.read(cryptoServiceProvider).deriveKeysFromPhrase(
            phrase,
            appDomain: ref.read(sanctuaryAppDomainProvider),
          );
      return (key: keys.masterEncryptionKey, phrase: phrase);
    } on ArgumentError {
      if (context.mounted) {
        _snack(context, 'That is not a valid recovery phrase.');
      }
      return null;
    }
  }

  void _afterRestore(WidgetRef ref) {
    // Inventory lists are Drift watch-streams that self-refresh on the restore
    // writes; nudge the dashboard snapshot (§2.5).
    ref.invalidate(dashboardSummaryProvider);
  }

  Future<bool?> _confirmMerge(
    BuildContext context, {
    required bool photosIncluded,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('Restore this backup?'),
          // With the mandatory pre-restore snapshot, "cannot be undone"
          // stopped being true, so the copy stopped saying it (the
          // BackupFlow precedent). The snapshot's scope matches what the
          // restore can overwrite, and the copy matches the snapshot.
          content: Text(
            photosIncluded
                ? 'Restoring merges this backup into Still Life on this '
                    'device, overwriting records and photos that share an '
                    'id. A snapshot of what is on this device now — photos '
                    'included — is saved to "Previous photo backups" first, '
                    'so you can roll back.'
                : 'Restoring merges this backup into Still Life on this '
                    'device, overwriting records that share an id — photos '
                    'on this device are kept. A snapshot of this device\'s '
                    'records — without photos, since none can be '
                    'overwritten — is saved first, so you can roll back.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

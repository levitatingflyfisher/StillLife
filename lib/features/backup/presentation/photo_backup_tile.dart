import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:share_plus/share_plus.dart';

import '../photo_backup_providers.dart';
import 'photo_restore_flow.dart';
import 'photo_snapshots_section.dart';

/// Settings tiles for the full, photos-included `.ohbkz` backup — a companion
/// to the metadata-only `.ohbk` flow in `BackupSettingsSection`
/// (SANCTUARY-BRIEF §4.W3). Export needs a key; restore prompts for the
/// recovery words when this device has none. Every restore routes through
/// [PhotoRestoreFlow] → `PhotoRestoreGuard` (mandatory fail-closed snapshot,
/// BACKUP_RETENTION_SPEC §2.B), and the snapshots themselves are managed in
/// the embedded [PhotoSnapshotsSection].
class PhotoBackupTile extends ConsumerWidget {
  const PhotoBackupTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    return authAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (authState) {
        final hasKey =
            authState.masterEncryptionKey != null && authState.seedAcknowledged;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasKey)
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Export with photos'),
                subtitle: const Text(
                  'Full encrypted backup including photo & receipt images '
                  '(.ohbkz)',
                ),
                onTap: () => _exportWithPhotos(context, ref),
              ),
            ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: const Text('Restore with photos'),
              subtitle: const Text('From a .ohbkz (or .ohbk) file'),
              onTap: () => _restoreWithPhotos(context, ref),
            ),
            // The photo-ful snapshot vault (keep-N 2): the rollback the
            // restore dialog promises, restorable/deletable in place.
            PhotoSnapshotsSection(
              vault: ref.watch(photoBackupVaultProvider),
              onRestoreSnapshot: (id) async {
                final bytes =
                    await ref.read(photoBackupVaultProvider).read(id);
                if (bytes == null || !context.mounted) return;
                // Same guarded flow as a picked file — restoring a snapshot
                // takes its own counter-snapshot first. The section already
                // confirmed with merge-honest copy, so the flow's own
                // confirm is skipped: one action, one dialog.
                await const PhotoRestoreFlow()
                    .restorePicked(context, ref, bytes, skipConfirm: true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportWithPhotos(BuildContext context, WidgetRef ref) async {
    final container = ref.read(photoBackupContainerProvider);
    final key = (await ref.read(authNotifierProvider.future)).masterEncryptionKey;
    if (key == null || !context.mounted) return;

    // Size estimate first, so the user consents to the payload.
    final est = await container.estimate();
    if (!context.mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export with photos?'),
        content: Text(
          'This creates an encrypted .ohbkz backup with '
          '${est.photoCount} photo(s) and ${est.receiptCount} receipt image(s) '
          '— about ${_formatBytes(est.totalBytes)} of images, plus your '
          'inventory records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;

    try {
      final result = await container.exportContainer(key);
      await Share.shareXFiles([
        XFile.fromData(
          result.bytes,
          mimeType: 'application/octet-stream',
          name: result.filename,
        ),
      ], fileNameOverrides: [result.filename]);
      if (result.skipped.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.skipped.length} image(s) were too large (over 10 MB) '
              'and were left out.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _restoreWithPhotos(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    final files = picked?.files ?? const [];
    final bytes = files.isEmpty ? null : files.first.bytes;
    if (bytes == null || !context.mounted) return;

    await const PhotoRestoreFlow().restorePicked(context, ref, bytes);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

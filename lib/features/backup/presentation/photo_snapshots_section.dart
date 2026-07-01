import 'package:flutter/material.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart'
    show BackupVault, VaultEntry, VaultLabel, formatBackupAge;

/// The "Previous photo backups" list — StillLife's face of the photo-ful
/// snapshot vault (the PunctumTemporis MetadataSnapshotsSection pattern).
class PhotoSnapshotsSection extends StatefulWidget {
  const PhotoSnapshotsSection({
    super.key,
    required this.vault,
    required this.onRestoreSnapshot,
  });

  final BackupVault vault;

  /// Called with the snapshot id after the user confirms; the owner routes
  /// it through the guarded restore flow and reports the outcome.
  final Future<void> Function(String id) onRestoreSnapshot;

  @override
  State<PhotoSnapshotsSection> createState() => _PhotoSnapshotsSectionState();
}

class _PhotoSnapshotsSectionState extends State<PhotoSnapshotsSection> {
  late Future<List<VaultEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.vault.list();
  }

  void _refresh() {
    final next = widget.vault.list();
    setState(() {
      _entries = next;
    });
  }

  String _labelText(VaultLabel label) => switch (label) {
        VaultLabel.preRestore => 'Safety snapshot',
        VaultLabel.manual => 'Manual snapshot',
        VaultLabel.freshness => 'Automatic snapshot',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<VaultEntry>>(
      future: _entries,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        if (entries == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Previous photo backups',
                  style: theme.textTheme.titleSmall),
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'No photo snapshots yet — one is saved automatically '
                  'before every photo restore.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              for (final entry in entries)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.history),
                  title: Text(_labelText(entry.label)),
                  subtitle:
                      Text(formatBackupAge(entry.createdAt, DateTime.now())),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_backup_restore),
                        tooltip: 'Restore this snapshot',
                        onPressed: () => _confirmRestore(context, entry),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete snapshot',
                        onPressed: () => _confirmDelete(context, entry),
                      ),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRestore(BuildContext context, VaultEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Restore this snapshot?'),
        // Merge-honest: the import is an upsert-merge, not a rollback —
        // records/photos sharing an id are overwritten, everything added
        // since the snapshot stays put. Saying "rolls back" would promise
        // deletions that never happen.
        content: Text(
          'Restoring merges this snapshot '
          '(${formatBackupAge(entry.createdAt, DateTime.now())}) into Still '
          'Life on this device, overwriting records and photos that share an '
          'id. Items you added since the snapshot stay put. A snapshot of '
          'the current state is saved first, so you can change your mind '
          'again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.onRestoreSnapshot(entry.id);
    _refresh();
  }

  Future<void> _confirmDelete(BuildContext context, VaultEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Delete snapshot?'),
        content: const Text(
            'This removes the snapshot from this device. Backups you '
            'exported elsewhere are not affected.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.vault.delete(entry.id);
    _refresh();
  }
}

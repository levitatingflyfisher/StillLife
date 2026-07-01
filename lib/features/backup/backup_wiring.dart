import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../../core/providers/repository_providers.dart';
import '../../services/backup/still_life_backup_serializer.dart';
import '../dashboard/presentation/controllers/dashboard_controller.dart';

/// Root-scope overrides that wire the generic `sanctuary_backup_ui` to
/// StillLife (SANCTUARY-BRIEF §4.W3). Applied on the `ProviderContainer` in
/// `main.dart`.
List<Override> sanctuaryBackupOverrides() => [
  sanctuaryBackupConfigProvider.overrideWithValue(
    SanctuaryBackupConfig(
      appId: 'stilllife',
      // A blob for this context can never be decrypted under another app's
      // (§2.3). Distinct from the LAN-sync 'stilllife-lan/v1' context.
      aadContext: 'stilllife-backup/v1',
      appDisplayName: 'Still Life',
      // Honest copy: the metadata restore is an upsert-merge, NOT a wipe —
      // photo BLOBs the backup omits are preserved, and items added since the
      // backup remain. Do not imply the database will match the backup exactly.
      restoreReplaceConsequence:
          'Restoring merges this backup into Still Life on this device, '
          'overwriting any records that share an id. Photos already on this '
          'device are kept, and items you added since the backup stay put.',
      // The package defaults ('Replace all data?' / 'Replace everything')
      // describe a destructive replace — over a merge they'd be a dark
      // pattern in reverse: scarier than the truth. backup_config.dart
      // requires merge apps to override both.
      confirmTitle: 'Merge backup into this device?',
      confirmActionLabel: 'Merge backup',
      onAfterRestore: (ref) {
        // Inventory lists are Drift watch-streams that self-refresh on the
        // restore writes; the dashboard headline is a one-shot snapshot, so
        // nudge it explicitly (§2.5).
        ref.invalidate(dashboardSummaryProvider);
      },
    ),
  ),
  backupSerializerProvider.overrideWith(
    (ref) => StillLifeBackupSerializer(
      exportService: ref.watch(exportServiceProvider),
      importService: ref.watch(importServiceProvider),
    ),
  ),
  // Isolate StillLife's key material from any other app sharing a household
  // seed (§2.1).
  sanctuaryAppDomainProvider.overrideWithValue('stilllife'),
];

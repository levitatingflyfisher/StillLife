import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../../core/providers/database_provider.dart';
import '../../services/backup/photo_backup_container.dart';
import '../../services/backup/photo_restore_guard.dart';

/// The `.ohbkz` photos-included backup container, wired from the app's data.
final photoBackupContainerProvider = Provider<PhotoBackupContainer>((ref) {
  return PhotoBackupContainer(
    db: ref.watch(databaseProvider),
    metadataRepo: ref.watch(backupRepositoryProvider),
    cipher: ref.watch(envelopeCipherProvider),
  );
});

/// Where photo-ful snapshots persist. A SECOND store, scoped
/// 'stilllife-photos' so the multi-MB `.ohbkz` snapshots never crowd the
/// metadata vault (BACKUP_RETENTION_SPEC §3's StillLife exception). Tests
/// override with `InMemoryVaultStore` from `testing.dart`.
final photoVaultStoreProvider = Provider<VaultStore>(
  (_) => createPlatformVaultStore(scope: 'stilllife-photos'),
);

/// The photo-ful snapshot vault: keep-N 2 (photos are MBs–GBs), `.ohbkz`
/// entries, pre-restore snapshots auto-pinned by the vault itself.
final photoBackupVaultProvider = Provider<BackupVault>((ref) {
  return BackupVault(
    ref.watch(photoVaultStoreProvider),
    appId: 'stilllife',
    keepN: 2,
    extension: 'ohbkz',
  );
});

/// The guarded photo-restore path — every photo-tile restore goes through
/// this, never straight to `importContainer` (BACKUP_RETENTION_SPEC §2.B).
final photoRestoreGuardProvider = Provider<PhotoRestoreGuard>((ref) {
  return PhotoRestoreGuard(
    container: ref.watch(photoBackupContainerProvider),
    metadataRepo: ref.watch(backupRepositoryProvider),
    photoVault: ref.watch(photoBackupVaultProvider),
    metadataVault: ref.watch(backupVaultProvider),
  );
});

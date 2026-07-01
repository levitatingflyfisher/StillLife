import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/features/backup/backup_wiring.dart';
import 'package:still_life/services/database/database.dart';

import '../../../test_setup.dart';

/// Proves the wiring behind main.dart's post-frame
/// `runStartupMaintenance()` hook: with StillLife's real overrides, the
/// silent freshness net (BACKUP_RETENTION_SPEC §3) can export through the
/// real serializer into the vault.
const _phrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon about';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late InMemoryVaultStore store;

  setUp(() {
    db = AppDatabase.memory();
    store = InMemoryVaultStore();
  });

  tearDown(() => db.close());

  ProviderContainer makeContainer({SecureKeyStore? keyStore}) {
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      secureKeyStoreProvider.overrideWithValue(keyStore ??
          InMemorySecureKeyStore(mnemonic: _phrase, acknowledged: true)),
      cryptoServiceProvider.overrideWithValue(FakeCryptoService()),
      vaultStoreProvider.overrideWithValue(store),
      ...sanctuaryBackupOverrides(),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('takes a freshness snapshot on an empty vault when a key exists',
      () async {
    final c = makeContainer();
    final took = await c
        .read(backupControllerProvider.notifier)
        .runStartupMaintenance();

    expect(took, isTrue);
    final entries = await store.list();
    expect(entries, hasLength(1));
    expect(entries.single.label, VaultLabel.freshness);

    // The snapshot is a real OHBK blob (magic bytes), not garbage.
    final bytes = await store.read(entries.single.id);
    expect(bytes!.sublist(0, 4), [0x4F, 0x48, 0x42, 0x4B]);
  });

  test('is a silent no-op right after a snapshot (nothing stale)', () async {
    final c = makeContainer();
    final controller = c.read(backupControllerProvider.notifier);
    await controller.runStartupMaintenance();
    expect(await controller.runStartupMaintenance(), isFalse);
    expect(await store.list(), hasLength(1));
  });

  test('is a silent no-op with no key (never surfaces errors)', () async {
    final c = makeContainer(keyStore: InMemorySecureKeyStore());
    expect(
        await c
            .read(backupControllerProvider.notifier)
            .runStartupMaintenance(),
        isFalse);
    expect(await store.list(), isEmpty);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/sync/crdt_manager.dart';
import '../../services/sync/lan_sync_server.dart';
import '../../services/sync/lan_sync_client.dart';
import '../../services/network/lan_discovery.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

/// The shared sync secret for this device (used to authenticate LAN sync).
final syncSecretProvider = FutureProvider<String>((ref) {
  return ref.watch(crdtManagerProvider).getSyncSecret();
});

final _secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final crdtManagerProvider = Provider<CrdtManager>((ref) {
  return CrdtManager(ref.watch(_secureStorageProvider));
});

final lanSyncServerProvider = Provider<LanSyncServer>((ref) {
  final server = LanSyncServer(
    db: ref.watch(databaseProvider),
    crdtManager: ref.watch(crdtManagerProvider),
    importService: ref.watch(importServiceProvider),
    exportService: ref.watch(exportServiceProvider),
  );
  ref.onDispose(() => server.stop());
  return server;
});

final lanDiscoveryProvider = Provider<LanDiscovery>((ref) {
  final discovery = LanDiscovery(crdtManager: ref.watch(crdtManagerProvider));
  ref.onDispose(() => discovery.dispose());
  return discovery;
});

final lanSyncClientProvider = Provider<LanSyncClient>((ref) {
  return LanSyncClient(
    crdtManager: ref.watch(crdtManagerProvider),
    exportService: ref.watch(exportServiceProvider),
    importService: ref.watch(importServiceProvider),
  );
});

import '../sync/crdt_manager.dart';
import '../../features/sync/domain/entities/sync_peer.dart';

/// Web stub: browsers cannot speak mDNS, so there are no peers to advertise
/// to or discover. API-compatible with the io implementation.
class LanDiscovery {
  LanDiscovery({required CrdtManager crdtManager});

  Future<void> startAdvertising() async {}

  Future<void> stopAdvertising() async {}

  Stream<SyncPeer> discoverPeers({
    Duration timeout = const Duration(seconds: 10),
  }) =>
      const Stream<SyncPeer>.empty();

  Future<void> dispose() async {}
}

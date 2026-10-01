import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/providers/sync_providers.dart';
import 'package:still_life/features/sync/domain/entities/sync_peer.dart';
import 'package:still_life/features/sync/presentation/controllers/sync_controller.dart';
import 'package:still_life/services/sync/lan_sync_client.dart';

class _Client extends Mock implements LanSyncClient {}

/// The count of rows this device held back on a sync reaches the peer's
/// result line; a later clean sync clears it.
void main() {
  test('a sync records how many changes were held back for that peer',
      () async {
    final client = _Client();
    final container = ProviderContainer(
      overrides: [lanSyncClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);
    const peer = SyncPeer(
      nodeId: 'n1',
      host: '10.0.0.2',
      port: 8420,
      deviceName: 'Den Phone',
    );
    final ctrl = container.read(syncControllerProvider.notifier);
    await container.read(syncControllerProvider.future);
    container.read(syncControllerProvider.notifier).state =
        const AsyncValue.data(SyncState(peers: [peer]));

    when(() => client.syncWith('10.0.0.2', 8420)).thenAnswer((_) async => 4);
    await ctrl.syncWithPeer(peer);
    expect(container.read(syncControllerProvider).value!.peers.single
        .lastHeldBack, 4);

    when(() => client.syncWith('10.0.0.2', 8420)).thenAnswer((_) async => 0);
    await ctrl.syncWithPeer(
        container.read(syncControllerProvider).value!.peers.single);
    expect(container.read(syncControllerProvider).value!.peers.single
        .lastHeldBack, 0);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/sync_providers.dart';
import '../../domain/entities/sync_peer.dart';

class SyncState {
  final List<SyncPeer> peers;
  final bool isSyncing;
  final String? lastError;
  final DateTime? lastSyncAt;

  const SyncState({
    this.peers = const [],
    this.isSyncing = false,
    this.lastError,
    this.lastSyncAt,
  });

  SyncState copyWith({
    List<SyncPeer>? peers,
    bool? isSyncing,
    String? lastError,
    bool clearError = false,
    DateTime? lastSyncAt,
  }) => SyncState(
    peers: peers ?? this.peers,
    isSyncing: isSyncing ?? this.isSyncing,
    lastError: clearError ? null : (lastError ?? this.lastError),
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
  );
}

class SyncController extends AsyncNotifier<SyncState> {
  @override
  Future<SyncState> build() async => const SyncState();

  /// Re-scans the network for peers.
  Future<void> startDiscovery() async {
    state = const AsyncValue.loading();
    final discovery = ref.read(lanDiscoveryProvider);

    final peers = <SyncPeer>[];
    state = AsyncValue.data(SyncState(peers: peers));

    try {
      await for (final peer in discovery.discoverPeers()) {
        peers.add(peer);
        state = AsyncValue.data(
          state.value!.copyWith(peers: List.unmodifiable(peers)),
        );
      }
    } catch (e) {
      state = AsyncValue.data(
        state.value?.copyWith(lastError: e.toString()) ??
            SyncState(lastError: e.toString()),
      );
    }
  }

  /// Runs bidirectional sync with [peer].
  Future<void> syncWithPeer(SyncPeer peer) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncValue.data(
      current.copyWith(isSyncing: true, clearError: true),
    );

    try {
      final client = ref.read(lanSyncClientProvider);
      await client.syncWith(peer.host, peer.port);

      final now = DateTime.now();
      final updatedPeers = current.peers.map((p) {
        return p.nodeId == peer.nodeId ? p.copyWith(lastSyncAt: now) : p;
      }).toList();

      state = AsyncValue.data(
        SyncState(peers: updatedPeers, isSyncing: false, lastSyncAt: now),
      );
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(isSyncing: false, lastError: e.toString()),
      );
    }
  }

  /// Adds a manually-entered peer by IP address.
  Future<void> addManualPeer(String host, int port) async {
    try {
      final client = ref.read(lanSyncClientProvider);
      final status = await client.getStatus(host, port);

      final peer = SyncPeer(
        nodeId: status.nodeId,
        host: host,
        port: port,
        deviceName: status.deviceName,
      );

      final current = state.value ?? const SyncState();
      final existing = current.peers.any((p) => p.nodeId == peer.nodeId);
      if (!existing) {
        state = AsyncValue.data(
          current.copyWith(peers: [...current.peers, peer]),
        );
      }
    } catch (e) {
      final current = state.value ?? const SyncState();
      state = AsyncValue.data(
        current.copyWith(lastError: 'Could not reach $host:$port — $e'),
      );
    }
  }
}

final syncControllerProvider = AsyncNotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

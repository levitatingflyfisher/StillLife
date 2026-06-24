import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nsd/nsd.dart';

import '../sync/crdt_manager.dart';
import '../../features/sync/domain/entities/sync_peer.dart';

const _serviceType = '_stilllife._tcp';
const _syncPort = 8420;

/// Advertises and discovers Still Life peers on the local network via mDNS.
class LanDiscovery {
  final CrdtManager _crdtManager;

  Registration? _registration;
  Discovery? _discovery;

  LanDiscovery({required CrdtManager crdtManager}) : _crdtManager = crdtManager;

  /// Advertises this device as a Still Life sync server.
  Future<void> startAdvertising() async {
    if (_registration != null) return;
    try {
      final nodeId = await _crdtManager.getNodeId();
      _registration = await register(
        Service(
          name: 'StillLife-$nodeId',
          type: _serviceType,
          port: _syncPort,
          txt: {'nodeId': Uint8List.fromList(utf8.encode(nodeId))},
        ),
      );
    } catch (_) {
      // mDNS may not be available on all platforms — that is OK.
    }
  }

  /// Stops advertising.
  Future<void> stopAdvertising() async {
    if (_registration != null) {
      try {
        await unregister(_registration!);
      } catch (_) {}
      _registration = null;
    }
  }

  /// Discovers other Still Life instances on the network.
  /// Polls for [timeout] then stops.
  Stream<SyncPeer> discoverPeers({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    final ownNodeId = await _crdtManager.getNodeId();
    final seen = <String>{};

    try {
      _discovery = await startDiscovery(_serviceType);
      final deadline = DateTime.now().add(timeout);

      while (DateTime.now().isBefore(deadline)) {
        for (final service in _discovery!.services) {
          final addresses = service.addresses;
          if (addresses == null || addresses.isEmpty) continue;

          final ip = addresses.first.address;
          final port = service.port ?? _syncPort;
          final txt = service.txt ?? {};
          final nodeIdBytes = txt['nodeId'];
          final nodeId = nodeIdBytes != null ? utf8.decode(nodeIdBytes) : '';

          // Skip ourselves.
          if (nodeId == ownNodeId) continue;

          final key = '$ip:$port';
          if (seen.contains(key)) continue;
          seen.add(key);

          final deviceName = service.name ?? ip;

          yield SyncPeer(
            nodeId: nodeId,
            host: ip,
            port: port,
            deviceName: deviceName,
          );
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } catch (_) {
      // Discovery may fail on some platforms — that is OK.
    } finally {
      if (_discovery != null) {
        try {
          await stopDiscovery(_discovery!);
        } catch (_) {}
        _discovery = null;
      }
    }
  }

  /// Clean up all resources.
  Future<void> dispose() async {
    await stopAdvertising();
    if (_discovery != null) {
      try {
        await stopDiscovery(_discovery!);
      } catch (_) {}
      _discovery = null;
    }
  }
}

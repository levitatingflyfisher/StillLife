import 'package:equatable/equatable.dart';

/// A Still Life peer discovered on the local network.
class SyncPeer extends Equatable {
  final String nodeId;
  final String host;
  final int port;
  final String deviceName;
  final DateTime? lastSyncAt;

  const SyncPeer({
    required this.nodeId,
    required this.host,
    required this.port,
    required this.deviceName,
    this.lastSyncAt,
  });

  SyncPeer copyWith({DateTime? lastSyncAt}) => SyncPeer(
    nodeId: nodeId,
    host: host,
    port: port,
    deviceName: deviceName,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
  );

  @override
  List<Object?> get props => [nodeId, host, port, deviceName, lastSyncAt];
}

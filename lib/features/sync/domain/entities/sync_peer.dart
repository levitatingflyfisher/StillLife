import 'package:equatable/equatable.dart';

/// A Still Life peer discovered on the local network.
class SyncPeer extends Equatable {
  final String nodeId;
  final String host;
  final int port;
  final String deviceName;
  final DateTime? lastSyncAt;

  /// How many of this peer's changes the last sync held back for a later
  /// one (waiting for a parent, or stamped ahead of this device's clock).
  final int lastHeldBack;

  const SyncPeer({
    required this.nodeId,
    required this.host,
    required this.port,
    required this.deviceName,
    this.lastSyncAt,
    this.lastHeldBack = 0,
  });

  SyncPeer copyWith({DateTime? lastSyncAt, int? lastHeldBack}) => SyncPeer(
    nodeId: nodeId,
    host: host,
    port: port,
    deviceName: deviceName,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastHeldBack: lastHeldBack ?? this.lastHeldBack,
  );

  @override
  List<Object?> get props =>
      [nodeId, host, port, deviceName, lastSyncAt, lastHeldBack];
}

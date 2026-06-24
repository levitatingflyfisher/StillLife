import 'package:crdt/crdt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

const _nodeIdKey = 'sync_node_id';
const _hlcKey = 'sync_hlc';
const _syncSecretKey = 'sync_secret';

/// Manages the node identity, Hybrid Logical Clock, and sync secret for CRDT sync.
class CrdtManager {
  final FlutterSecureStorage _storage;

  String? _nodeId;
  String? _syncSecret;
  Hlc _hlc = Hlc.zero('');

  CrdtManager(this._storage);

  /// Returns the persistent node UUID for this device.
  /// Created on first call and stored in secure storage.
  Future<String> getNodeId() async {
    if (_nodeId != null) return _nodeId!;
    _nodeId = await _storage.read(key: _nodeIdKey);
    if (_nodeId == null || _nodeId!.isEmpty) {
      _nodeId = const Uuid().v4();
      await _storage.write(key: _nodeIdKey, value: _nodeId);
    }
    return _nodeId!;
  }

  /// Returns the shared sync secret for this device (used to authenticate LAN sync).
  /// Generated on first call and stored in secure storage.
  Future<String> getSyncSecret() async {
    if (_syncSecret != null) return _syncSecret!;
    _syncSecret = await _storage.read(key: _syncSecretKey);
    if (_syncSecret == null || _syncSecret!.isEmpty) {
      _syncSecret = const Uuid().v4();
      await _storage.write(key: _syncSecretKey, value: _syncSecret);
    }
    return _syncSecret!;
  }

  /// Minimum acceptable sync secret length, in characters.
  ///
  /// The LAN sync server authenticates every request against this value as a
  /// bearer token. Short secrets are trivially brute-forceable, so we refuse
  /// to accept them.
  static const int minSyncSecretLength = 16;

  /// Replaces the sync secret (e.g. user copies code from another device).
  ///
  /// Throws [ArgumentError] if [secret] is shorter than
  /// [minSyncSecretLength] characters.
  Future<void> setSyncSecret(String secret) async {
    if (secret.length < minSyncSecretLength) {
      throw ArgumentError.value(
        secret,
        'secret',
        'Sync code must be at least $minSyncSecretLength characters.',
      );
    }
    _syncSecret = secret;
    await _storage.write(key: _syncSecretKey, value: secret);
  }

  /// The current in-memory HLC value without advancing it.
  Hlc get currentHlc => _hlc;

  /// Returns the next monotonically-increasing HLC timestamp, persisting it.
  Future<Hlc> nextHlc() async {
    final nodeId = await getNodeId();
    if (_hlc.nodeId.isEmpty) {
      final stored = await _storage.read(key: _hlcKey);
      _hlc = stored != null && stored.isNotEmpty
          ? Hlc.parse(stored)
          : Hlc.zero(nodeId);
    }
    _hlc = _hlc.increment();
    await _storage.write(key: _hlcKey, value: _hlc.toString());
    return _hlc;
  }

  /// Merges a remote HLC into the local clock (LWW: takes the max) and persists.
  Future<Hlc> mergeHlc(String remoteHlcStr) async {
    if (remoteHlcStr.isEmpty) return _hlc;
    try {
      final remote = Hlc.parse(remoteHlcStr);
      _hlc = _hlc.merge(remote);
      await _storage.write(key: _hlcKey, value: _hlc.toString());
      return _hlc;
    } catch (_) {
      return _hlc;
    }
  }
}

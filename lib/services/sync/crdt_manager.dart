import 'package:crdt/crdt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

const _nodeIdKey = 'sync_node_id';
const _hlcKey = 'sync_hlc';
const _syncSecretKey = 'sync_secret';

/// Manages the node identity, Hybrid Logical Clock, and sync secret for CRDT sync.
class CrdtManager {
  final FlutterSecureStorage _storage;

  Hlc _hlc = Hlc.zero('');

  CrdtManager(this._storage);

  /// The in-flight or finished mint, memoized.
  ///
  /// Caching the VALUE is not enough: `_x != null` is false for every caller
  /// that arrives while the first one is still awaiting storage, so each
  /// mints its own UUID and the last write wins — eight concurrent callers
  /// observed three identities against a 5 ms read. Caching the FUTURE means
  /// they all await the same single mint.
  ///
  /// Deliberately not the `_serialized` queue used for the clock: [nextHlc]
  /// calls [getNodeId] from inside that queue, and a non-reentrant lock
  /// there would deadlock.
  Future<String>? _nodeIdOnce;
  Future<String>? _syncSecretOnce;

  /// Returns the persistent node UUID for this device.
  /// Created on first call and stored in secure storage.
  ///
  /// Identity must be answered identically every time: a device that returns
  /// two node ids has, as far as every peer is concerned, become two devices
  /// — and their HLC streams then interleave with no way to tell them apart.
  Future<String> getNodeId() =>
      _nodeIdOnce ??= _readOrMint(_nodeIdKey);

  /// Returns the shared sync secret for this device (used to authenticate LAN sync).
  /// Generated on first call and stored in secure storage.
  Future<String> getSyncSecret() =>
      _syncSecretOnce ??= _readOrMint(_syncSecretKey);

  Future<String> _readOrMint(String key) async {
    final stored = await _storage.read(key: key);
    if (stored != null && stored.isNotEmpty) return stored;
    final minted = const Uuid().v4();
    await _storage.write(key: key, value: minted);
    return minted;
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
    // Replace the memo, not just the field: a reader that already resolved
    // would otherwise keep handing back the previous secret, so pairing with
    // the other device would report success and change nothing.
    _syncSecretOnce = Future.value(secret);
    await _storage.write(key: _syncSecretKey, value: secret);
  }

  /// The current in-memory HLC value without advancing it.
  Hlc get currentHlc => _hlc;

  /// Serializes clock mutations.
  ///
  /// Every method below reads `_hlc`, awaits secure storage, then writes
  /// `_hlc` back. Without this queue those three steps interleave: twenty
  /// concurrent callers all observe the same value before any of them
  /// stores its increment, and all twenty receive the SAME stamp. That was
  /// not hypothetical — it is what a sync does, since it stamps many rows
  /// without awaiting between them.
  ///
  /// A stamp is a position in a total order. Two rows sharing a position
  /// are two rows last-writer-wins cannot choose between, so the winner
  /// falls to whichever device happens to iterate first — the one thing
  /// sync must never depend on.
  ///
  /// Scope: this serializes one instance. Sharing that instance is the
  /// provider's job (`core/providers/sync_providers.dart`); two live
  /// managers over the same storage would still race, which is why nothing
  /// should construct this outside that provider.
  Future<void> _queue = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() op) {
    final result = _queue.then((_) => op());
    // Keep the chain alive past a failure, or one thrown stamp would wedge
    // the clock for the rest of the session.
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  /// Returns the next monotonically-increasing HLC timestamp, persisting it.
  Future<Hlc> nextHlc() => _serialized(() async {
        final nodeId = await getNodeId();
        if (_hlc.nodeId.isEmpty) {
          _hlc = _parseOrZero(await _storage.read(key: _hlcKey), nodeId);
        }
        _hlc = _hlc.increment();
        await _storage.write(key: _hlcKey, value: _hlc.toString());
        return _hlc;
      });

  /// A stored clock we cannot read starts over rather than throwing. Losing
  /// the counter costs an ordering hint; throwing here would take out every
  /// write that asked for a stamp, which is the whole app.
  static Hlc _parseOrZero(String? stored, String nodeId) {
    if (stored == null || stored.isEmpty) return Hlc.zero(nodeId);
    try {
      return Hlc.parse(stored);
    } catch (_) {
      return Hlc.zero(nodeId);
    }
  }

  /// Merges a remote HLC into the local clock (LWW: takes the max) and persists.
  Future<Hlc> mergeHlc(String remoteHlcStr) {
    if (remoteHlcStr.isEmpty) return Future.value(_hlc);
    return _serialized(() async {
      try {
        final remote = Hlc.parse(remoteHlcStr);
        _hlc = _hlc.merge(remote);
        await _storage.write(key: _hlcKey, value: _hlc.toString());
        return _hlc;
      } catch (_) {
        // A bad remote stamp never breaks local time.
        return _hlc;
      }
    });
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/sync/crdt_manager.dart';

/// Hands every local write its sync stamp (nodeId + HLC).
///
/// Yellow paper §3: an incoming row replaces the local one only when its HLC
/// is strictly greater, and an unstamped incoming row only fills a hole. So
/// a write that is not stamped loses to anything: an edit or delete that
/// never reaches a device already holding the row. Repositories run their DAO writes through [write] so
/// every create, edit and delete carries a stamp.
///
/// Stamping must never cost the household a save: the clock lives in secure
/// storage, and a keystore hiccup must not become "couldn't save your item".
/// If stamping fails, the write goes through unstamped and the failure is
/// logged; the row then reaches only devices that lack it, and any stamped
/// write replaces it.
class SyncStamp {
  const SyncStamp([this._crdt]);

  /// No stamping (tests and tools that have no clock).
  static const none = SyncStamp();

  final CrdtManager? _crdt;

  Future<T> write<T>(Future<T> Function(CrdtManager? crdt) op) async {
    final crdt = _crdt;
    if (crdt == null) return op(null);
    try {
      // Bounded: a keystore that never answers must not hang the save.
      await crdt.getNodeId().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Still Life: sync clock unavailable, write unstamped: $e');
      return op(null);
    }
    try {
      return await op(crdt);
    } catch (e) {
      // Was it the clock? Ask it once more; if it cannot stamp, the write
      // itself was never the problem, so save without a stamp.
      try {
        await crdt.nextHlc();
      } catch (_) {
        debugPrint('Still Life: sync clock failed mid-write, unstamped: $e');
        return op(null);
      }
      rethrow;
    }
  }
}

import 'dart:convert';

import '../export/import_service.dart';
import 'changeset.dart';
import 'crdt_manager.dart';

/// Result of applying a remote changeset.
class MergeResult {
  final int recordsApplied;
  final String? error;

  const MergeResult({required this.recordsApplied, this.error});

  bool get isSuccess => error == null;
}

/// Applies remote changesets to the local database using LWW semantics
/// (Last Write Wins, determined by HLC ordering).
class MergeEngine {
  final ImportService _importService;
  final CrdtManager _crdtManager;

  MergeEngine({
    required ImportService importService,
    required CrdtManager crdtManager,
  }) : _importService = importService,
       _crdtManager = crdtManager;

  /// Applies [remote] changeset to the local DB and merges the remote HLC.
  Future<MergeResult> apply(SyncChangeset remote) async {
    // Fail closed on a payload from a newer app version: its semantics may
    // have changed (row shapes, units), and misreading them would corrupt
    // local data silently. Nothing is written before this check.
    if (remote.payloadSchemaVersion >
        SyncChangeset.currentPayloadSchemaVersion) {
      return MergeResult(
        recordsApplied: 0,
        error:
            'The other device runs a newer version of Still Life '
            '(sync payload v${remote.payloadSchemaVersion}, this app '
            'understands v${SyncChangeset.currentPayloadSchemaVersion}). '
            'Update this app, then sync again.',
      );
    }
    try {
      // Re-encode the data portion as JSON for ImportService.
      final jsonString = const JsonEncoder().convert({
        'version': '1.0',
        'app': 'still_life',
        'data': remote.data,
      });

      // lww: this is a peer MERGE, not a restore — apply a row only when it is
      // strictly newer (HLC) than the local one, so a stale peer can't clobber
      // newer local edits or resurrect a newer tombstone.
      final result = await _importService.importFromJson(jsonString, lww: true);
      await _crdtManager.mergeHlc(remote.senderHlc);

      return result.when(
        success: (summary) => MergeResult(recordsApplied: summary.totalRecords),
        failure: (f) => MergeResult(recordsApplied: 0, error: f.message),
      );
    } catch (e) {
      return MergeResult(recordsApplied: 0, error: e.toString());
    }
  }
}

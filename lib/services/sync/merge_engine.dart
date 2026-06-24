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
    try {
      // Re-encode the data portion as JSON for ImportService.
      final jsonString = const JsonEncoder().convert({
        'version': '1.0',
        'app': 'still_life',
        'data': remote.data,
      });

      final result = await _importService.importFromJson(jsonString);
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

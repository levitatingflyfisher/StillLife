import 'dart:convert';
import 'dart:typed_data';

import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../export/import_service.dart';
import '../export/json_export_service.dart';

/// Bridges StillLife's existing JSON export/import engine to the sanctuary
/// encrypted-backup pipeline (SANCTUARY-BRIEF §4.W3).
///
/// Scope is METADATA: the JSON envelope ships `photosIncluded: false`, so the
/// bare `.ohbk` carries the inventory records but not photo/receipt image
/// BLOBs (those ride the `.ohbkz` container). [restoreAll] is therefore an
/// upsert-merge, NOT a wipe — a wipe would destroy the photo bytes the
/// metadata backup deliberately omits (verified by the serializer test's
/// preservation case). This is a conscious deviation from §2.5's
/// destructive-replace; the restore-confirmation copy is set honestly via
/// `SanctuaryBackupConfig` (merge title/action + consequence), and
/// `_isPathSafe` (ADR-0006) still runs inside `importFromJson`.
///
/// NOTE the two ids in play: the JSON envelope's `app` key is `'still_life'`
/// (the shipped wire value — changing it would orphan every existing backup),
/// while the vault/config appId is `'stilllife'` (filenames, AEAD context
/// stems). Both are load-bearing; neither may be "harmonized".
class StillLifeBackupSerializer
    implements BackupSerializer, PreviewableBackupSerializer {
  final JsonExportService _exportService;
  final ImportService _importService;

  /// The envelope's `app` value — see the class note on the two ids.
  static const String _wireAppId = 'still_life';

  /// Highest envelope major version this build can restore. The export
  /// envelope carries `version: '1.0'`; a backup whose major exceeds this was
  /// written by a newer app and is rejected (§2.8).
  static const int currentEnvelopeVersion = 1;

  /// The v2 int schema version gate (BACKUP_RETENTION_SPEC §2.F), stamped by
  /// [JsonExportService] and checked via [BackupEnvelope.unwrap].
  static const int currentSchemaVersion = JsonExportService.currentSchemaVersion;

  StillLifeBackupSerializer({
    required JsonExportService exportService,
    required ImportService importService,
  }) : _exportService = exportService,
       _importService = importService;

  @override
  Future<Uint8List> dumpAll() async {
    final jsonString = await _exportService.exportToJson();
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  /// The dry-run parse behind preview-before-restore and export
  /// verify-by-read-back (BACKUP_RETENTION_SPEC §2.C/§2.D): validates via
  /// the exact gate [restoreAll] applies — wrong app, future string major,
  /// future int schemaVersion, non-JSON — then describes without writing.
  @override
  Future<BackupManifest> describeBackup(Uint8List plaintext) async {
    _requireStillLifeEnvelope(plaintext);
    // describe() counts StillLife's legacy top-level `data` map natively.
    return BackupEnvelope.describe(plaintext);
  }

  @override
  Future<void> restoreAll(Uint8List plaintext) async {
    final jsonString = _requireStillLifeEnvelope(plaintext);

    // Upsert-merge: overwrite matching rows by id, preserving photo/receipt
    // BLOBs the metadata backup omits (the companions leave those columns
    // absent, so insertOnConflictUpdate never nulls them).
    final result = await _importService.importFromJson(jsonString, lww: false);
    result.when(
      success: (_) {},
      failure: (f) =>
          throw BackupFormatException('Restore failed: ${f.message}'),
    );
  }

  /// The one shared validation gate (the Sundial/Lullaby pattern): both
  /// [describeBackup] and [restoreAll] run exactly this, so preview and
  /// restore can never drift apart. Returns the decoded JSON string for the
  /// importer.
  ///
  /// Defense in depth behind the AEAD context, twice over:
  /// 1. The legacy gate every shipped backup satisfies: `app == 'still_life'`
  ///    plus the string `version` major (§2.8).
  /// 2. The fleet-standard [BackupEnvelope.unwrap] gate on the int
  ///    `schemaVersion` — applied only when the envelope carries that key,
  ///    because legacy blobs predate it and MUST keep restoring
  ///    (wire-compat law; proven by the legacy-blob test).
  static String _requireStillLifeEnvelope(Uint8List plaintext) {
    final String jsonString;
    final Map<String, dynamic> envelope;
    try {
      jsonString = utf8.decode(plaintext);
      envelope = json.decode(jsonString) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw BackupFormatException(
          'Backup payload is not valid JSON: ${e.message}');
    }

    if (envelope['app'] != _wireAppId) {
      throw BackupFormatException('Not a Still Life backup.');
    }
    final major = _majorVersion(envelope['version']);
    if (major > currentEnvelopeVersion) {
      throw BackupSchemaException(major, currentEnvelopeVersion);
    }

    if (envelope.containsKey('schemaVersion')) {
      // Throws BackupSchemaException for a future int schemaVersion and
      // FormatException for a malformed one — both map to the same restore
      // outcomes the legacy gate produces.
      BackupEnvelope.unwrap(
        plaintext,
        expectedAppId: _wireAppId,
        currentSchemaVersion: currentSchemaVersion,
      );
    }
    return jsonString;
  }

  static int _majorVersion(Object? version) {
    if (version is! String) return 0;
    final dot = version.indexOf('.');
    final head = dot >= 0 ? version.substring(0, dot) : version;
    return int.tryParse(head) ?? 0;
  }
}

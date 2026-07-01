import 'package:crdt/crdt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/sync/changeset.dart';
import 'package:still_life/services/sync/crdt_manager.dart';
import 'package:still_life/services/sync/merge_engine.dart';

class _MockImportService extends Mock implements ImportService {}

class _MockCrdtManager extends Mock implements CrdtManager {}

/// The sync wire carries a payload schema version so a FUTURE change to
/// payload semantics (e.g. a unit change) can never flow silently into an
/// older app and be misread. Backup already has this gate; sync was the
/// uncovered wire. Absent version (every changeset shipped before the field
/// existed) means version 1 — today's dollars-on-the-wire payload.
void main() {
  setUpAll(() {
    registerFallbackValue(Hlc.zero(''));
  });

  group('SyncChangeset payload schema version', () {
    test('stamps the current version into its JSON', () {
      const cs = SyncChangeset(
        senderNodeId: 'n1',
        senderHlc: 'h1',
        data: {},
      );
      expect(cs.payloadSchemaVersion, SyncChangeset.currentPayloadSchemaVersion);
      expect(
        cs.toJson()['payloadSchemaVersion'],
        SyncChangeset.currentPayloadSchemaVersion,
      );
    });

    test('a legacy changeset without the field parses as version 1', () {
      final cs = SyncChangeset.fromJson({
        'senderNodeId': 'n1',
        'senderHlc': 'h1',
        'data': <String, dynamic>{},
      });
      expect(cs.payloadSchemaVersion, 1);
    });

    test('an explicit version survives the JSON round-trip', () {
      final cs = SyncChangeset.fromJsonString(
        const SyncChangeset(
          senderNodeId: 'n1',
          senderHlc: 'h1',
          data: {},
          payloadSchemaVersion: 3,
        ).toJsonString(),
      );
      expect(cs.payloadSchemaVersion, 3);
    });
  });

  group('MergeEngine payload schema gate', () {
    test('refuses a future payload version before touching the database',
        () async {
      final importService = _MockImportService();
      final crdtManager = _MockCrdtManager();
      final engine = MergeEngine(
        importService: importService,
        crdtManager: crdtManager,
      );

      final result = await engine.apply(
        const SyncChangeset(
          senderNodeId: 'n1',
          senderHlc: 'h1',
          data: {},
          payloadSchemaVersion: SyncChangeset.currentPayloadSchemaVersion + 1,
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.recordsApplied, 0);
      expect(result.error, contains('newer'),
          reason: 'the error must tell the user their app is older');
      verifyNever(
        () => importService.importFromJson(any(), lww: any(named: 'lww')),
      );
      verifyNever(() => crdtManager.mergeHlc(any()));
    });
  });
}

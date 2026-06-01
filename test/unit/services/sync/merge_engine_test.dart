import 'package:crdt/crdt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/sync/changeset.dart';
import 'package:still_life/services/sync/crdt_manager.dart';
import 'package:still_life/services/sync/merge_engine.dart';

class _MockImportService extends Mock implements ImportService {}

class _MockCrdtManager extends Mock implements CrdtManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(Hlc.zero(''));
  });

  late _MockImportService importService;
  late _MockCrdtManager crdtManager;
  late MergeEngine engine;

  setUp(() {
    importService = _MockImportService();
    crdtManager = _MockCrdtManager();
    engine = MergeEngine(
      importService: importService,
      crdtManager: crdtManager,
    );
  });

  SyncChangeset makeChangeset({
    Map<String, dynamic>? data,
    String senderNodeId = 'remote-node',
    String senderHlc = '2025-01-01T00:00:00.000Z:0@remote-node',
  }) => SyncChangeset(
    senderNodeId: senderNodeId,
    senderHlc: senderHlc,
    data:
        data ??
        {
          'items': <dynamic>[],
          'properties': <dynamic>[],
          'rooms': <dynamic>[],
          'categories': <dynamic>[],
          'tags': <dynamic>[],
          'itemTags': <dynamic>[],
          'photos': <dynamic>[],
          'receipts': <dynamic>[],
          'priceHistory': <dynamic>[],
          'policies': <dynamic>[],
          'maintenanceLogs': <dynamic>[],
        },
  );

  group('MergeEngine.apply', () {
    test('success: returns recordsApplied from ImportSummary', () async {
      when(
        () => importService.importFromJson(any()),
      ).thenAnswer((_) async => const Success(ImportSummary(items: 3)));

      // Use a manager that doesn't throw on mergeHlc
      final silentCrdt = _MockCrdtManager();
      when(
        () => silentCrdt.mergeHlc(any()),
      ).thenAnswer((_) async => Hlc.zero(''));
      final localEngine = MergeEngine(
        importService: importService,
        crdtManager: silentCrdt,
      );

      final result = await localEngine.apply(makeChangeset());

      expect(result.isSuccess, isTrue);
      expect(result.recordsApplied, 3);
    });

    test('failure: returns error from ImportService', () async {
      when(
        () => importService.importFromJson(any()),
      ).thenAnswer((_) async => const Err(ImportFailure('bad json')));
      final silentCrdt = _MockCrdtManager();
      when(
        () => silentCrdt.mergeHlc(any()),
      ).thenAnswer((_) async => Hlc.zero(''));

      final localEngine = MergeEngine(
        importService: importService,
        crdtManager: silentCrdt,
      );

      final result = await localEngine.apply(makeChangeset());

      expect(result.isSuccess, isFalse);
      expect(result.error, 'bad json');
      expect(result.recordsApplied, 0);
    });

    test('exception: wraps in MergeResult with error', () async {
      when(
        () => importService.importFromJson(any()),
      ).thenThrow(Exception('network timeout'));
      final silentCrdt = _MockCrdtManager();
      when(
        () => silentCrdt.mergeHlc(any()),
      ).thenAnswer((_) async => Hlc.zero(''));

      final localEngine = MergeEngine(
        importService: importService,
        crdtManager: silentCrdt,
      );

      final result = await localEngine.apply(makeChangeset());

      expect(result.isSuccess, isFalse);
      expect(result.error, contains('network timeout'));
    });

    test('SyncChangeset serialises and deserialises round-trip', () {
      final cs = makeChangeset(senderNodeId: 'abc', senderHlc: 'hlc-val');
      final json = cs.toJson();
      final cs2 = SyncChangeset.fromJson(json);

      expect(cs2.senderNodeId, 'abc');
      expect(cs2.senderHlc, 'hlc-val');
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';
import 'package:still_life/services/sync/changeset.dart';
import 'package:still_life/services/sync/crdt_manager.dart';
import 'package:still_life/services/sync/lan_sync_client.dart';

class _MockDio extends Mock implements Dio {}

class _MockCrdtManager extends Mock implements CrdtManager {}

class _MockExportService extends Mock implements JsonExportService {}

class _MockImportService extends Mock implements ImportService {}

void main() {
  late _MockDio dio;
  late _MockCrdtManager crdtManager;
  late _MockExportService exportService;
  late _MockImportService importService;
  late LanSyncClient client;

  const host = '192.168.1.42';
  const port = 8420;

  setUp(() {
    dio = _MockDio();
    crdtManager = _MockCrdtManager();
    exportService = _MockExportService();
    importService = _MockImportService();

    client = LanSyncClient(
      crdtManager: crdtManager,
      exportService: exportService,
      importService: importService,
      dio: dio,
    );

    // Auth stub — getSyncSecret is called before every request
    when(
      () => crdtManager.getSyncSecret(),
    ).thenAnswer((_) async => 'test-secret');
    // Default Dio options stub — needed for constructor in real Dio
    when(() => dio.options).thenReturn(BaseOptions());
  });

  group('LanSyncClient.getStatus', () {
    test('parses status response', () async {
      final responseData = {
        'nodeId': 'remote-id',
        'hlc': 'hlc-value',
        'itemCount': 5,
        'deviceName': 'Living Room Tablet',
      };
      when(
        () => dio.get<dynamic>(
          any(),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: responseData,
          statusCode: 200,
        ),
      );

      final status = await client.getStatus(host, port);

      expect(status.nodeId, 'remote-id');
      expect(status.itemCount, 5);
      expect(status.deviceName, 'Living Room Tablet');
    });
  });

  group('LanSyncClient.fetchExport', () {
    test('parses SyncChangeset from JSON response', () async {
      const cs = SyncChangeset(
        senderNodeId: 'remote',
        senderHlc: 'hlc',
        data: {'items': <dynamic>[]},
      );
      when(
        () => dio.get<dynamic>(
          any(),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: cs.toJsonString(),
          statusCode: 200,
        ),
      );

      final result = await client.fetchExport(host, port);

      expect(result.senderNodeId, 'remote');
      expect(result.data.containsKey('items'), isTrue);
    });
  });

  group('LanSyncClient.pushExport', () {
    test('posts changeset and parses result', () async {
      when(
        () => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'recordsApplied': 7},
          statusCode: 200,
        ),
      );

      const cs = SyncChangeset(
        senderNodeId: 'local',
        senderHlc: 'hlc',
        data: {},
      );

      final result = await client.pushExport(host, port, cs);
      expect(result.recordsApplied, 7);
    });
  });
}

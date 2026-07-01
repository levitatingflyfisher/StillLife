import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';
import 'package:still_life/services/sync/changeset.dart';
import 'package:still_life/services/sync/crdt_manager.dart';
import 'package:still_life/services/sync/lan_sync_client.dart';
import 'package:still_life/services/sync/sync_codec.dart';

class _MockDio extends Mock implements Dio {}

class _MockCrdtManager extends Mock implements CrdtManager {}

class _MockExportService extends Mock implements JsonExportService {}

class _MockImportService extends Mock implements ImportService {}

const _secret = 'a-shared-sync-code-16chars';

void main() {
  late _MockDio dio;
  late _MockCrdtManager crdtManager;
  late LanSyncClient client;

  const host = '192.168.1.42';
  const port = 8420;

  Response<dynamic> okJson(Object data) => Response(
    requestOptions: RequestOptions(path: ''),
    data: data,
    statusCode: 200,
  );

  setUp(() {
    dio = _MockDio();
    crdtManager = _MockCrdtManager();

    client = LanSyncClient(
      crdtManager: crdtManager,
      exportService: _MockExportService(),
      importService: _MockImportService(),
      dio: dio,
    );

    when(() => crdtManager.getSyncSecret()).thenAnswer((_) async => _secret);
  });

  group('LanSyncClient.getStatus', () {
    test('parses proto + challenge from the cleartext probe', () async {
      when(() => dio.get<dynamic>(any())).thenAnswer(
        (_) async => okJson({
          'nodeId': 'remote-id',
          'hlc': 'hlc-value',
          'proto': 2,
          'challenge': 'Y2hhbGxlbmdl',
        }),
      );

      final status = await client.getStatus(host, port);

      expect(status.nodeId, 'remote-id');
      expect(status.proto, 2);
      expect(status.challenge, 'Y2hhbGxlbmdl');
      expect(status.supportsEncryptedSync, isTrue);
    });

    test('an old peer with no proto reads as unsupported', () async {
      when(() => dio.get<dynamic>(any())).thenAnswer(
        (_) async => okJson({'nodeId': 'old', 'hlc': '1'}),
      );

      final status = await client.getStatus(host, port);

      expect(status.proto, 1);
      expect(status.supportsEncryptedSync, isFalse);
    });
  });

  group('LanSyncClient.syncWith', () {
    test('refuses a peer that cannot encrypt (fail closed)', () async {
      when(() => dio.get<dynamic>(any())).thenAnswer(
        (_) async => okJson({'nodeId': 'old', 'hlc': '1', 'proto': 1}),
      );

      expect(
        () => client.syncWith(host, port),
        throwsA(
          isA<SyncProtocolException>().having(
            (e) => e.message,
            'message',
            kOutdatedSyncPeerMessage,
          ),
        ),
      );
    });
  });

  group('LanSyncClient.fetchExport', () {
    test('decrypts a sealed export frame into a changeset', () async {
      final key = await SyncCodec.deriveKey(_secret);
      const cs = SyncChangeset(
        senderNodeId: 'remote',
        senderHlc: 'hlc',
        data: {'items': <dynamic>[]},
      );
      final frame = await SyncCodec().seal(
        Uint8List.fromList(utf8.encode(cs.toJsonString())),
        key,
        endpointTag: SyncCodec.endpointExport,
      );

      when(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: frame,
          statusCode: 200,
        ),
      );

      final result = await client.fetchExport(host, port);

      expect(result.senderNodeId, 'remote');
      expect(result.data.containsKey('items'), isTrue);
    });
  });

  group('LanSyncClient.pushExport', () {
    test('seals the changeset under the import AAD + challenge', () async {
      final challengeBytes = Uint8List.fromList(List.filled(16, 7));
      final challenge = base64.encode(challengeBytes);

      Stream<List<int>>? capturedBody;
      Options? capturedOptions;
      when(
        () => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((inv) async {
        capturedBody = inv.namedArguments[#data] as Stream<List<int>>;
        capturedOptions = inv.namedArguments[#options] as Options;
        return okJson({'recordsApplied': 3});
      });

      const cs = SyncChangeset(
        senderNodeId: 'local',
        senderHlc: 'hlc',
        data: {},
      );

      final result = await client.pushExport(
        host,
        port,
        cs,
        challenge: challenge,
      );
      expect(result.recordsApplied, 3);

      // The challenge travels in the header ...
      expect(capturedOptions!.headers!['x-sync-challenge'], challenge);
      expect(capturedOptions!.contentType, 'application/octet-stream');

      // ... and the captured body is a real frame that opens under the same
      // key + import AAD + challenge (proving the client's encode path).
      final builder = BytesBuilder();
      await for (final chunk in capturedBody!) {
        builder.add(chunk);
      }
      final key = await SyncCodec.deriveKey(_secret);
      final opened = await SyncCodec().open(
        builder.takeBytes(),
        key,
        endpointTag: SyncCodec.endpointImport,
        challenge: challengeBytes,
      );
      expect(utf8.decode(opened), cs.toJsonString());
    });
  });
}

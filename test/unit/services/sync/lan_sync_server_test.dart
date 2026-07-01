import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crdt/crdt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';
import 'package:still_life/services/sync/crdt_manager.dart';
import 'package:still_life/services/sync/lan_sync_server.dart';
import 'package:still_life/services/sync/sync_codec.dart';

import '../../../test_setup.dart';

class _MockCrdtManager extends Mock implements CrdtManager {}

class _MockExportService extends Mock implements JsonExportService {}

class _MockImportService extends Mock implements ImportService {}

/// Finds a free TCP port so two-server tests never collide on 8420.
Future<int> findFreePort() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  await server.close();
  return port;
}

void main() {
  ensureSqlite3();

  late _MockCrdtManager crdtManager;
  late _MockExportService exportService;
  late _MockImportService importService;
  late LanSyncServer server;
  late int port;

  setUp(() async {
    // flutter_test installs a mock HttpClient that 400s every request; these
    // tests drive a real loopback socket, so restore the platform client.
    HttpOverrides.global = null;

    crdtManager = _MockCrdtManager();
    exportService = _MockExportService();
    importService = _MockImportService();

    port = await findFreePort();

    server = LanSyncServer(
      crdtManager: crdtManager,
      importService: importService,
      exportService: exportService,
      port: port,
    );
  });

  tearDown(() async {
    await server.stop();
  });

  Future<HttpClientResponse> get(String path) async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port$path'));
    final resp = await req.close();
    return resp;
  }

  group('LanSyncServer', () {
    test('starts and stops without error, on the requested port', () async {
      await server.start();
      expect(server.isRunning, isTrue);
      expect(server.port, port);
      await server.stop();
      expect(server.isRunning, isFalse);
    });

    test('/sync/status is a minimal cleartext probe (proto + challenge, '
        'no deviceName/itemCount leak)', () async {
      when(() => crdtManager.getNodeId()).thenAnswer((_) async => 'node-x');
      when(() => crdtManager.currentHlc).thenReturn(Hlc.zero('node-x'));

      await server.start();
      addTearDown(server.stop);

      final resp = await get('/sync/status');
      final body = await resp.transform(utf8.decoder).join();
      expect(resp.statusCode, 200);

      final parsed = json.decode(body) as Map<String, dynamic>;
      expect(parsed['nodeId'], 'node-x');
      expect(parsed['proto'], SyncCodec.protocolVersion);
      expect(parsed['challenge'], isA<String>());
      // Privacy: the old device-metadata fields are gone from the wire.
      expect(parsed.containsKey('deviceName'), isFalse);
      expect(parsed.containsKey('itemCount'), isFalse);
    });

    test('every /sync/status issues a fresh challenge', () async {
      when(() => crdtManager.getNodeId()).thenAnswer((_) async => 'node-x');
      when(() => crdtManager.currentHlc).thenReturn(Hlc.zero('node-x'));
      await server.start();
      addTearDown(server.stop);

      final a = json.decode(await (await get('/sync/status')).transform(utf8.decoder).join())
          as Map<String, dynamic>;
      final b = json.decode(await (await get('/sync/status')).transform(utf8.decoder).join())
          as Map<String, dynamic>;
      expect(a['challenge'], isNot(equals(b['challenge'])));
    });

    test('a plaintext /sync/import body is refused (fail closed) — 400, '
        'no merge', () async {
      when(() => crdtManager.getNodeId()).thenAnswer((_) async => 'node-x');
      when(() => crdtManager.currentHlc).thenReturn(Hlc.zero('node-x'));
      when(
        () => crdtManager.getSyncSecret(),
      ).thenAnswer((_) async => 'a-shared-sync-code-16chars');
      await server.start();
      addTearDown(server.stop);

      // Grab a valid challenge so we isolate the plaintext-body rejection
      // (not the missing-challenge rejection).
      final status = json.decode(
        await (await get('/sync/status')).transform(utf8.decoder).join(),
      ) as Map<String, dynamic>;
      final challenge = status['challenge'] as String;

      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port/sync/import'),
      );
      req.headers.set('x-sync-challenge', challenge);
      req.headers.contentType = ContentType('application', 'octet-stream');
      req.add(utf8.encode('{"senderNodeId":"evil","data":{}}'));
      final resp = await req.close();
      await resp.drain<void>();
      client.close();

      expect(resp.statusCode, 400);
      // The import engine was never invoked — no DB mutation path reached.
      verifyNever(
        () => importService.importFromJson(any(), lww: any(named: 'lww')),
      );
    });

    test('a merge failure returns a fixed 500 message — exception internals '
        'never reach the wire', () async {
      const secret = 'a-shared-sync-code-16chars';
      when(() => crdtManager.getNodeId()).thenAnswer((_) async => 'node-x');
      when(() => crdtManager.currentHlc).thenReturn(Hlc.zero('node-x'));
      when(() => crdtManager.getSyncSecret()).thenAnswer((_) async => secret);
      await server.start();
      addTearDown(server.stop);

      final status = json.decode(
        await (await get('/sync/status')).transform(utf8.decoder).join(),
      ) as Map<String, dynamic>;
      final challenge = status['challenge'] as String;

      // A frame that opens fine under the shared key but whose plaintext is
      // not a changeset — the merge path throws a FormatException that quotes
      // the offending (peer-supplied) bytes. None of that may be echoed back.
      final frame = await SyncCodec().seal(
        Uint8List.fromList(utf8.encode('this-is-not-json {')),
        await SyncCodec.deriveKey(secret),
        endpointTag: SyncCodec.endpointImport,
        challenge: base64.decode(challenge),
      );

      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port/sync/import'),
      );
      req.headers.set('x-sync-challenge', challenge);
      req.headers.contentType = ContentType('application', 'octet-stream');
      req.add(frame);
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();

      expect(resp.statusCode, 500);
      final parsed = json.decode(body) as Map<String, dynamic>;
      expect(parsed['error'], 'Merge failed.');
      expect(body, isNot(contains('FormatException')));
      expect(body, isNot(contains('this-is-not-json')));
    });

    test('a /sync/import with no challenge is rejected with 401', () async {
      when(
        () => crdtManager.getSyncSecret(),
      ).thenAnswer((_) async => 'a-shared-sync-code-16chars');
      await server.start();
      addTearDown(server.stop);

      final client = HttpClient();
      final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port/sync/import'),
      );
      req.headers.contentType = ContentType('application', 'octet-stream');
      req.add(utf8.encode('anything'));
      final resp = await req.close();
      await resp.drain<void>();
      client.close();

      expect(resp.statusCode, 401);
      verifyNever(
        () => importService.importFromJson(any(), lww: any(named: 'lww')),
      );
    });
  });
}

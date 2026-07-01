import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crdt/crdt.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';
import 'package:still_life/services/sync/changeset.dart';
import 'package:still_life/services/sync/crdt_manager.dart';
import 'package:still_life/services/sync/lan_sync_client.dart';
import 'package:still_life/services/sync/lan_sync_server.dart';
import 'package:still_life/services/sync/sync_codec.dart';

import '../../../test_setup.dart';

class _MockCrdtManager extends Mock implements CrdtManager {}

const _sharedSecret = 'household-sync-code-32-chars-long!';

/// A mocked clock/identity so the two nodes share a secret (→ same key) but
/// keep distinct node ids. Row-level HLCs travel inside the exported data;
/// senderHlc only feeds the clock merge, so a fixed stub suffices.
_MockCrdtManager _crdt(String nodeId) {
  final m = _MockCrdtManager();
  when(() => m.getNodeId()).thenAnswer((_) async => nodeId);
  when(() => m.getSyncSecret()).thenAnswer((_) async => _sharedSecret);
  when(() => m.currentHlc).thenReturn(Hlc.zero(nodeId));
  when(() => m.nextHlc()).thenAnswer((_) async => Hlc.zero(nodeId).increment());
  when(() => m.mergeHlc(any())).thenAnswer((_) async => Hlc.zero(nodeId));
  return m;
}

Future<int> _freePort() async {
  final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final p = s.port;
  await s.close();
  return p;
}

/// Seeds a full FK chain (property → room → category → item) for one item.
Future<void> _seedItem(AppDatabase db, String suffix) async {
  final now = DateTime(2026);
  await db.into(db.properties).insert(
    PropertiesCompanion.insert(
      id: 'p_$suffix',
      name: 'Home $suffix',
      createdAt: now,
      modifiedAt: now,
    ),
  );
  await db.into(db.rooms).insert(
    RoomsCompanion.insert(
      id: 'r_$suffix',
      propertyId: 'p_$suffix',
      name: 'Room $suffix',
      createdAt: now,
      modifiedAt: now,
    ),
  );
  await db.into(db.categories).insert(
    CategoriesCompanion.insert(
      id: 'c_$suffix',
      name: 'Cat $suffix',
      createdAt: now,
      modifiedAt: now,
    ),
  );
  await db.into(db.items).insert(
    ItemsCompanion.insert(
      id: 'item_$suffix',
      name: 'Item $suffix',
      categoryId: 'c_$suffix',
      roomId: 'r_$suffix',
      hlc: Value('1970-01-01T00:00:00.000Z-0000-$suffix'),
      createdAt: now,
      modifiedAt: now,
    ),
  );
}

Future<Set<String>> _itemIds(AppDatabase db) async {
  final rows = await db.select(db.items).get();
  return rows.map((r) => r.id).toSet();
}

void main() {
  ensureSqlite3();

  late AppDatabase dbA; // client node
  late AppDatabase dbB; // server node
  late LanSyncServer server;
  late LanSyncClient client;
  late int port;

  setUp(() async {
    // flutter_test installs a mock HttpClient that 400s every request; this
    // two-node test drives a real loopback socket via dio + shelf, so restore
    // the platform client.
    HttpOverrides.global = null;

    dbA = AppDatabase.memory();
    dbB = AppDatabase.memory();
    port = await _freePort();

    server = LanSyncServer(
      crdtManager: _crdt('node-b'),
      importService: ImportService(dbB),
      exportService: JsonExportService(dbB),
      port: port,
    );
    client = LanSyncClient(
      crdtManager: _crdt('node-a'),
      exportService: JsonExportService(dbA),
      importService: ImportService(dbA),
    );
    await server.start();
  });

  tearDown(() async {
    await server.stop();
    await dbA.close();
    await dbB.close();
  });

  test('two nodes converge over an encrypted wire (real server + real client)',
      () async {
    await _seedItem(dbA, 'alpha');
    await _seedItem(dbB, 'beta');

    await client.syncWith('127.0.0.1', port);

    // syncWith pulls B→A then pushes A→B, so both hold both items.
    expect(await _itemIds(dbA), containsAll({'item_alpha', 'item_beta'}));
    expect(await _itemIds(dbB), containsAll({'item_alpha', 'item_beta'}));
  });

  group('fail-closed at the live import boundary', () {
    // Raw poster that inspects the status code instead of throwing.
    Future<Response<dynamic>> rawPost(
      List<int> body, {
      String? challenge,
    }) async {
      final dio = Dio();
      return dio.post<dynamic>(
        'http://127.0.0.1:$port/sync/import',
        data: Stream<List<int>>.fromIterable([body]),
        options: Options(
          contentType: 'application/octet-stream',
          responseType: ResponseType.json,
          validateStatus: (_) => true,
          headers: {
            'x-sync-challenge': ?challenge,
            Headers.contentLengthHeader: body.length,
          },
        ),
      );
    }

    Future<String> freshChallenge() async {
      final status = await client.getStatus('127.0.0.1', port);
      return status.challenge!;
    }

    Future<Uint8List> sealImport(String changesetJson, String challenge) async {
      return SyncCodec().seal(
        Uint8List.fromList(utf8.encode(changesetJson)),
        await SyncCodec.deriveKey(_sharedSecret),
        endpointTag: SyncCodec.endpointImport,
        challenge: base64.decode(challenge),
      );
    }

    test('a tampered frame is rejected 400 with no DB mutation', () async {
      await _seedItem(dbB, 'beta');
      final before = await _itemIds(dbB);

      final challenge = await freshChallenge();
      const cs = SyncChangeset(
        senderNodeId: 'node-a',
        senderHlc: '1',
        data: {},
      );
      final frame = await sealImport(cs.toJsonString(), challenge);
      frame[SyncCodec.frameOverhead] ^= 0xFF; // corrupt the ciphertext

      final resp = await rawPost(frame, challenge: challenge);

      expect(resp.statusCode, 400);
      expect(await _itemIds(dbB), before, reason: 'no mutation on a bad frame');
    });

    test('a replayed import is rejected 401 (single-use challenge)', () async {
      final challenge = await freshChallenge();

      // A genuinely valid changeset (built from a real export so it satisfies
      // the import engine), sealed for import.
      final src = AppDatabase.memory();
      await _seedItem(src, 'x');
      final exportData =
          json.decode(await JsonExportService(src).exportToJson())
              as Map<String, dynamic>;
      await src.close();
      final cs = SyncChangeset(
        senderNodeId: 'node-a',
        senderHlc: '1',
        data: exportData['data'] as Map<String, dynamic>,
      );
      final frame = await sealImport(cs.toJsonString(), challenge);

      final first = await rawPost(frame, challenge: challenge);
      expect(first.statusCode, 200);
      final afterFirst = await _itemIds(dbB);
      expect(afterFirst, contains('item_x'));

      // Replay the identical bytes + identical challenge.
      final replay = await rawPost(frame, challenge: challenge);
      expect(replay.statusCode, 401, reason: 'challenge already consumed');
      expect(await _itemIds(dbB), afterFirst, reason: 'no double-apply');
    });
  });
}

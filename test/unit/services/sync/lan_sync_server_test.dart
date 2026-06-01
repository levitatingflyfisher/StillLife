import 'dart:convert';
import 'dart:io';

import 'package:crdt/crdt.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';
import 'package:still_life/services/sync/crdt_manager.dart';
import 'package:still_life/services/sync/lan_sync_server.dart';

import '../../../test_setup.dart';

class _MockCrdtManager extends Mock implements CrdtManager {}

class _MockExportService extends Mock implements JsonExportService {}

class _MockImportService extends Mock implements ImportService {}

/// Finds a free TCP port.
Future<int> findFreePort() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  await server.close();
  return port;
}

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late _MockCrdtManager crdtManager;
  late _MockExportService exportService;
  late _MockImportService importService;
  late LanSyncServer server;
  late int port;

  setUp(() async {
    db = AppDatabase.memory();
    crdtManager = _MockCrdtManager();
    exportService = _MockExportService();
    importService = _MockImportService();

    port = await findFreePort();

    server = LanSyncServer(
      db: db,
      crdtManager: crdtManager,
      importService: importService,
      exportService: exportService,
    );
  });

  tearDown(() async {
    await server.stop();
    await db.close();
  });

  group('LanSyncServer', () {
    test('starts and stops without error', () async {
      await server.start();
      expect(server.isRunning, isTrue);
      await server.stop();
      expect(server.isRunning, isFalse);
    });

    test('/sync/status itemCount excludes soft-deleted items', () async {
      // Stub the bare minimum of CrdtManager that _handleStatus calls.
      when(() => crdtManager.getNodeId()).thenAnswer((_) async => 'node-x');
      when(() => crdtManager.getSyncSecret()).thenAnswer((_) async => 's3cr');
      when(() => crdtManager.currentHlc).thenReturn(Hlc.zero('node-x'));

      // Seed FK chain: property → room → category → 1 live + 1 deleted item.
      final now = DateTime(2026);
      await db
          .into(db.properties)
          .insert(
            PropertiesCompanion.insert(
              id: 'p1',
              name: 'Home',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'r1',
              propertyId: 'p1',
              name: 'Kitchen',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'c1',
              name: 'Food',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'live',
              name: 'Live',
              categoryId: 'c1',
              roomId: 'r1',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'tomb',
              name: 'Tomb',
              categoryId: 'c1',
              roomId: 'r1',
              isDeleted: const Value(true),
              createdAt: now,
              modifiedAt: now,
            ),
          );

      await server.start();
      addTearDown(server.stop);

      final client = HttpClient();
      final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:8420/sync/status'),
      );
      req.headers.set('authorization', 'Bearer s3cr');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();

      expect(resp.statusCode, 200);
      final parsed = json.decode(body) as Map<String, dynamic>;
      expect(parsed['itemCount'], 1, reason: 'tomb must not be counted');
    });
  });
}

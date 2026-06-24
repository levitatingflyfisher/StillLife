import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../database/database.dart';
import '../export/import_service.dart';
import '../export/json_export_service.dart';
import 'changeset.dart';
import 'crdt_manager.dart';
import 'merge_engine.dart';

const _syncPort = 8420;

/// Embedded HTTP server exposing Still Life sync endpoints on the LAN.
class LanSyncServer {
  final AppDatabase _db;
  final CrdtManager _crdtManager;
  final ImportService _importService;
  final JsonExportService _exportService;

  HttpServer? _server;
  MergeEngine? _mergeEngine;

  LanSyncServer({
    required AppDatabase db,
    required CrdtManager crdtManager,
    required ImportService importService,
    required JsonExportService exportService,
  }) : _db = db,
       _crdtManager = crdtManager,
       _importService = importService,
       _exportService = exportService;

  bool get isRunning => _server != null;

  /// Middleware that logs request method + path in debug builds only.
  /// Critically, it never logs headers (Authorization contains the Bearer
  /// sync secret) or request bodies.
  Middleware _redactedLogger() {
    return (Handler inner) {
      return (Request req) async {
        if (kDebugMode) {
          debugPrint('[LanSyncServer] ${req.method} ${req.requestedUri.path}');
        }
        return inner(req);
      };
    };
  }

  /// Middleware that validates the shared sync secret.
  Middleware _authMiddleware() {
    return (Handler inner) {
      return (Request request) async {
        final secret = await _crdtManager.getSyncSecret();
        final auth = request.headers['authorization'] ?? '';
        if (auth != 'Bearer $secret') {
          return Response(
            401,
            body: const JsonEncoder().convert({'error': 'Unauthorized'}),
            headers: {'content-type': 'application/json'},
          );
        }
        return inner(request);
      };
    };
  }

  /// Starts listening on 0.0.0.0:8420.
  Future<void> start() async {
    if (_server != null) return;

    _mergeEngine = MergeEngine(
      importService: _importService,
      crdtManager: _crdtManager,
    );

    final router = Router()
      ..get('/sync/status', _handleStatus)
      ..get('/sync/export', _handleExport)
      ..post('/sync/import', _handleImport);

    final handler = const Pipeline()
        .addMiddleware(_redactedLogger())
        .addMiddleware(_authMiddleware())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _syncPort);
  }

  /// Stops the server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<Response> _handleStatus(Request request) async {
    final nodeId = await _crdtManager.getNodeId();
    // Use currentHlc — no side effects on a read-only status check.
    final hlcStr = _crdtManager.currentHlc.toString();
    // Count only live items so the status panel reflects what users see in
    // the inventory list (soft-deleted tombstones stay out of the headline).
    final itemCount =
        await (_db.select(_db.items)..where((t) => t.isDeleted.equals(false)))
            .get()
            .then((rows) => rows.length);
    final deviceName = Platform.localHostname;

    return Response.ok(
      const JsonEncoder().convert({
        'nodeId': nodeId,
        'hlc': hlcStr,
        'itemCount': itemCount,
        'deviceName': deviceName,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _handleExport(Request request) async {
    final nodeId = await _crdtManager.getNodeId();
    final hlc = await _crdtManager.nextHlc();
    final exportJson = await _exportService.exportToJson();
    final exportData = json.decode(exportJson) as Map<String, dynamic>;

    final changeset = SyncChangeset(
      senderNodeId: nodeId,
      senderHlc: hlc.toString(),
      data: exportData['data'] as Map<String, dynamic>? ?? {},
    );

    return Response.ok(
      changeset.toJsonString(),
      headers: {'content-type': 'application/json'},
    );
  }

  static const _maxBodyBytes = 20 * 1024 * 1024; // 20 MB

  Future<Response> _handleImport(Request request) async {
    // Reject oversized payloads before reading into memory.
    final rawLen = request.headers['content-length'];
    final declaredLen = rawLen != null ? int.tryParse(rawLen) : null;
    if (declaredLen != null && declaredLen > _maxBodyBytes) {
      return Response(
        413,
        body: const JsonEncoder().convert({'error': 'Payload too large'}),
        headers: {'content-type': 'application/json'},
      );
    }

    try {
      final body = await request.readAsString();
      if (body.length > _maxBodyBytes) {
        return Response(
          413,
          body: const JsonEncoder().convert({'error': 'Payload too large'}),
          headers: {'content-type': 'application/json'},
        );
      }
      final changeset = SyncChangeset.fromJsonString(body);
      final result = await _mergeEngine!.apply(changeset);

      final status = result.isSuccess ? 200 : 422;
      return Response(
        status,
        body: const JsonEncoder().convert({
          'recordsApplied': result.recordsApplied,
          if (result.error != null) 'error': result.error,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: const JsonEncoder().convert({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}

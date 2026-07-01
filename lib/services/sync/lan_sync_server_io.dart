import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../export/import_service.dart';
import '../export/json_export_service.dart';
import 'changeset.dart';
import 'crdt_manager.dart';
import 'merge_engine.dart';
import 'replay_challenge_store.dart';
import 'sync_codec.dart';

const _syncPort = 8420;

/// Header carrying the single-use replay challenge on `/sync/import`.
const _challengeHeader = 'x-sync-challenge';

/// Embedded HTTP server exposing Still Life sync endpoints on the LAN.
///
/// The wire is encrypted (SANCTUARY-BRIEF §4.W3): `/sync/export` and
/// `/sync/import` bodies are binary AEAD frames (`nonce ‖ ciphertext ‖ mac`,
/// see [SyncCodec]) sealed under a key HKDF-derived from the shared sync
/// secret. `/sync/status` stays a minimal cleartext probe that negotiates the
/// protocol version and issues a single-use replay challenge. There is NO
/// plaintext-body path — a frame that will not open is rejected before it
/// touches the DB (fail closed).
///
/// AEAD possession replaces the old `Authorization: Bearer` gate: producing a
/// frame that opens under the shared key IS the proof of pairing, so the
/// non-constant-time string compare the yellow paper flagged is gone.
///
/// NOTE(sync + photo BLOBs): sync payloads intentionally do NOT carry photo
/// bytes — JSON export ships `photosIncluded: false`, exactly as it did before
/// schema v12 moved photos into BLOB columns; the v12 change does not alter
/// sync semantics. If photo bytes are ever added to sync, revisit
/// [_maxPlaintextBytes] (20 MB) first.
class LanSyncServer {
  final CrdtManager _crdtManager;
  final ImportService _importService;
  final JsonExportService _exportService;
  final SyncCodec _codec;
  final ReplayChallengeStore _challenges;
  final int _port;

  HttpServer? _server;
  MergeEngine? _mergeEngine;

  LanSyncServer({
    required CrdtManager crdtManager,
    required ImportService importService,
    required JsonExportService exportService,
    SyncCodec? codec,
    ReplayChallengeStore? challenges,
    int port = _syncPort,
  }) : _crdtManager = crdtManager,
       _importService = importService,
       _exportService = exportService,
       _codec = codec ?? SyncCodec(),
       _challenges = challenges ?? ReplayChallengeStore(),
       _port = port;

  bool get isRunning => _server != null;

  /// The port this server binds — exposed so a caller (or a two-node test) can
  /// discover the actual port when it was bound to an ephemeral one.
  int get port => _server?.port ?? _port;

  /// Middleware that logs request method + path in debug builds only.
  /// Critically, it never logs headers or request bodies.
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

  /// Starts listening on 0.0.0.0:[_port].
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
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
  }

  /// Stops the server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<Uint8List> _key() async =>
      SyncCodec.deriveKey(await _crdtManager.getSyncSecret());

  /// `/sync/status` — a minimal cleartext capability probe.
  ///
  /// It intentionally drops the old `deviceName` and `itemCount` fields to
  /// shrink the cleartext leak (SANCTUARY-BRIEF §4.W3). It advertises the
  /// protocol version and issues a single-use replay challenge the peer must
  /// echo on `/sync/import`.
  Future<Response> _handleStatus(Request request) async {
    final nodeId = await _crdtManager.getNodeId();
    // Use currentHlc — no side effects on a read-only status check.
    final hlcStr = _crdtManager.currentHlc.toString();
    final challenge = _challenges.issue();

    return Response.ok(
      const JsonEncoder().convert({
        'nodeId': nodeId,
        'hlc': hlcStr,
        'proto': SyncCodec.protocolVersion,
        'challenge': challenge,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  /// `/sync/export` — returns the local snapshot as an encrypted binary frame.
  ///
  /// Read-only: it only advances the sender clock. It carries no request body,
  /// so there is no AEAD possession proof; confidentiality is preserved (the
  /// response is ciphertext), and triggering an export is benign. This
  /// asymmetry is documented in the sync-encryption ADR.
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

    final frame = await _codec.seal(
      Uint8List.fromList(utf8.encode(changeset.toJsonString())),
      await _key(),
      endpointTag: SyncCodec.endpointExport,
    );

    return Response.ok(
      frame,
      headers: {'content-type': 'application/octet-stream'},
    );
  }

  // 20 MB, measured against the DECRYPTED changeset. The pre-read gate adds
  // the fixed AEAD overhead so a legitimately-20 MB plaintext is not rejected.
  static const _maxPlaintextBytes = 20 * 1024 * 1024;
  static const _maxFrameBytes = _maxPlaintextBytes + SyncCodec.frameOverhead;

  Future<Response> _handleImport(Request request) async {
    // Reject oversized payloads before reading into memory.
    final declaredLen = request.contentLength;
    if (declaredLen != null && declaredLen > _maxFrameBytes) {
      return _tooLarge();
    }

    // Read the raw frame bytes (binary, not a string).
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      builder.add(chunk);
      if (builder.length > _maxFrameBytes) {
        return _tooLarge();
      }
    }
    final frame = builder.takeBytes();

    // Single-use replay challenge: the peer must echo one we issued and have
    // not yet consumed. Reject BEFORE decrypt so a replay never mutates the DB.
    final token = request.headers[_challengeHeader];
    final challenge = token == null ? null : _challenges.consume(token);
    if (challenge == null) {
      return Response(
        401,
        body: const JsonEncoder().convert({
          'error': 'Missing or already-used sync challenge.',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    // Open the frame. Any structural or authentication failure (plaintext
    // body, tampered bytes, wrong key/AAD) is a fail-closed 400 with no DB
    // mutation.
    final Uint8List plaintext;
    try {
      plaintext = await _codec.open(
        frame,
        await _key(),
        endpointTag: SyncCodec.endpointImport,
        challenge: challenge,
      );
    } on SanctuaryAuthException catch (e) {
      return Response(
        400,
        body: const JsonEncoder().convert({'error': e.message}),
        headers: {'content-type': 'application/json'},
      );
    }

    if (plaintext.length > _maxPlaintextBytes) {
      return _tooLarge();
    }

    try {
      final changeset = SyncChangeset.fromJsonString(utf8.decode(plaintext));
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
      // Never echo exception internals to the peer: a raw toString() can
      // quote peer-supplied bytes, file paths, or SQL fragments. The wire gets
      // a fixed message; the detail stays in local debug logs only.
      if (kDebugMode) {
        debugPrint('[LanSyncServer] import merge failed: $e');
      }
      return Response.internalServerError(
        body: const JsonEncoder().convert({'error': 'Merge failed.'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Response _tooLarge() => Response(
    413,
    body: const JsonEncoder().convert({'error': 'Payload too large'}),
    headers: {'content-type': 'application/json'},
  );
}

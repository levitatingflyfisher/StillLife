import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../export/import_service.dart';
import '../export/json_export_service.dart';
import 'changeset.dart';
import 'crdt_manager.dart';
import 'merge_engine.dart';
import 'sync_codec.dart';

/// Header carrying the single-use replay challenge on `/sync/import`.
const _challengeHeader = 'x-sync-challenge';

/// Copy shown when a peer is too old to encrypt (fail closed — never sync in
/// the clear). SANCTUARY-BRIEF §4.W3.
const kOutdatedSyncPeerMessage =
    'Update StillLife on your other device to sync securely.';

/// Status info returned by a remote node's cleartext `/sync/status` probe.
class SyncStatus {
  final String nodeId;
  final String hlc;

  /// Wire-protocol version. Absent (an old plaintext peer) is read as `1`.
  final int proto;

  /// The single-use replay challenge to echo on the next push. Null for a peer
  /// that does not speak the encrypted protocol.
  final String? challenge;

  const SyncStatus({
    required this.nodeId,
    required this.hlc,
    this.proto = 1,
    this.challenge,
  });

  factory SyncStatus.fromJson(Map<String, dynamic> json) => SyncStatus(
    nodeId: json['nodeId'] as String? ?? '',
    hlc: json['hlc'] as String? ?? '',
    proto: json['proto'] as int? ?? 1,
    challenge: json['challenge'] as String?,
  );

  /// Whether this peer speaks the encrypted sync protocol this build requires.
  bool get supportsEncryptedSync =>
      proto >= SyncCodec.protocolVersion && challenge != null;
}

/// Thrown when a peer cannot speak the encrypted sync protocol.
///
/// Its [message] is user-facing copy the controller surfaces directly, so the
/// household updates the other device instead of falling back to plaintext.
class SyncProtocolException implements Exception {
  final String message;
  SyncProtocolException([this.message = kOutdatedSyncPeerMessage]);
  @override
  String toString() => message;
}

/// Result of pushing a changeset to a remote node.
class PushResult {
  final int recordsApplied;
  final String? error;

  const PushResult({required this.recordsApplied, this.error});

  factory PushResult.fromJson(Map<String, dynamic> json) => PushResult(
    recordsApplied: json['recordsApplied'] as int? ?? 0,
    error: json['error'] as String?,
  );
}

/// HTTP client for communicating with remote LAN sync servers.
///
/// The wire is encrypted (SANCTUARY-BRIEF §4.W3): export/import bodies are
/// binary AEAD frames ([SyncCodec]) sealed under the HKDF key derived from the
/// shared sync secret; `/sync/status` negotiates the protocol version and
/// carries the single-use replay challenge. There is no plaintext fallback —
/// a peer that cannot encrypt is refused.
class LanSyncClient {
  final CrdtManager _crdtManager;
  final JsonExportService _exportService;
  final ImportService _importService;
  final SyncCodec _codec;
  final Dio _dio;

  LanSyncClient({
    required CrdtManager crdtManager,
    required JsonExportService exportService,
    required ImportService importService,
    SyncCodec? codec,
    Dio? dio,
  }) : _crdtManager = crdtManager,
       _exportService = exportService,
       _importService = importService,
       _codec = codec ?? SyncCodec(),
       _dio =
           dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  String _baseUrl(String host, int port) => 'http://$host:$port';

  Future<Uint8List> _key() async =>
      SyncCodec.deriveKey(await _crdtManager.getSyncSecret());

  static Map<String, dynamic> _asMap(dynamic data) => data is String
      ? json.decode(data) as Map<String, dynamic>
      : data as Map<String, dynamic>;

  /// Fetches status from a remote node (cleartext capability probe).
  Future<SyncStatus> getStatus(String host, int port) async {
    final response = await _dio.get<dynamic>('${_baseUrl(host, port)}/sync/status');
    return SyncStatus.fromJson(_asMap(response.data));
  }

  /// Fetches the full export changeset from a remote node, decrypting the
  /// binary frame. Throws a CryptoException if the peer's key does not match
  /// ours (unpaired devices cannot sync — fail closed).
  Future<SyncChangeset> fetchExport(String host, int port) async {
    final response = await _dio.get<List<int>>(
      '${_baseUrl(host, port)}/sync/export',
      options: Options(responseType: ResponseType.bytes),
    );
    final frame = Uint8List.fromList(response.data ?? const <int>[]);
    final plaintext = await _codec.open(
      frame,
      await _key(),
      endpointTag: SyncCodec.endpointExport,
    );
    return SyncChangeset.fromJsonString(utf8.decode(plaintext));
  }

  /// Pushes our local export to a remote node as an encrypted frame, binding
  /// the single-use [challenge] the peer issued via `/sync/status`.
  Future<PushResult> pushExport(
    String host,
    int port,
    SyncChangeset cs, {
    required String challenge,
  }) async {
    final frame = await _codec.seal(
      Uint8List.fromList(utf8.encode(cs.toJsonString())),
      await _key(),
      endpointTag: SyncCodec.endpointImport,
      challenge: base64.decode(challenge),
    );
    final response = await _dio.post<dynamic>(
      '${_baseUrl(host, port)}/sync/import',
      // Stream the raw bytes so dio never string-encodes the frame.
      data: Stream<List<int>>.fromIterable([frame]),
      options: Options(
        contentType: 'application/octet-stream',
        responseType: ResponseType.json,
        headers: {
          _challengeHeader: challenge,
          Headers.contentLengthHeader: frame.length,
        },
      ),
    );
    return PushResult.fromJson(_asMap(response.data));
  }

  /// Full bidirectional sync with a peer:
  /// 1. Negotiate over `/sync/status` — refuse a peer that cannot encrypt.
  /// 2. Fetch their export → merge into our DB.
  /// 3. Push our export → they merge into theirs.
  Future<void> syncWith(String host, int port) async {
    final status = await getStatus(host, port);
    if (!status.supportsEncryptedSync) {
      throw SyncProtocolException();
    }

    final mergeEngine = MergeEngine(
      importService: _importService,
      crdtManager: _crdtManager,
    );

    // Step 1: Pull from remote.
    final remote = await fetchExport(host, port);
    await mergeEngine.apply(remote);

    // Step 2: Push to remote.
    final nodeId = await _crdtManager.getNodeId();
    final hlc = await _crdtManager.nextHlc();
    final exportJson = await _exportService.exportToJson();
    final exportData =
        const JsonDecoder().convert(exportJson) as Map<String, dynamic>;

    final cs = SyncChangeset(
      senderNodeId: nodeId,
      senderHlc: hlc.toString(),
      data: exportData['data'] as Map<String, dynamic>? ?? {},
    );
    await pushExport(host, port, cs, challenge: status.challenge!);
  }
}

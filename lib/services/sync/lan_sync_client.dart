import 'dart:convert';

import 'package:dio/dio.dart';

import '../export/import_service.dart';
import '../export/json_export_service.dart';
import 'changeset.dart';
import 'crdt_manager.dart';
import 'merge_engine.dart';

/// Status info returned by a remote node.
class SyncStatus {
  final String nodeId;
  final String hlc;
  final int itemCount;
  final String deviceName;

  const SyncStatus({
    required this.nodeId,
    required this.hlc,
    required this.itemCount,
    required this.deviceName,
  });

  factory SyncStatus.fromJson(Map<String, dynamic> json) => SyncStatus(
    nodeId: json['nodeId'] as String? ?? '',
    hlc: json['hlc'] as String? ?? '',
    itemCount: json['itemCount'] as int? ?? 0,
    deviceName: json['deviceName'] as String? ?? 'Unknown',
  );
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
class LanSyncClient {
  final CrdtManager _crdtManager;
  final JsonExportService _exportService;
  final ImportService _importService;
  final Dio _dio;

  LanSyncClient({
    required CrdtManager crdtManager,
    required JsonExportService exportService,
    required ImportService importService,
    Dio? dio,
  }) : _crdtManager = crdtManager,
       _exportService = exportService,
       _importService = importService,
       _dio =
           dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  String _baseUrl(String host, int port) => 'http://$host:$port';

  /// Returns the Authorization header using the shared sync secret.
  Future<Options> _authOptions({Map<String, dynamic>? extra}) async {
    final secret = await _crdtManager.getSyncSecret();
    return Options(headers: {'Authorization': 'Bearer $secret', ...?extra});
  }

  /// Fetches status from a remote node.
  Future<SyncStatus> getStatus(String host, int port) async {
    final response = await _dio.get<dynamic>(
      '${_baseUrl(host, port)}/sync/status',
      options: await _authOptions(),
    );
    return SyncStatus.fromJson(response.data as Map<String, dynamic>);
  }

  /// Fetches the full export changeset from a remote node.
  Future<SyncChangeset> fetchExport(String host, int port) async {
    final response = await _dio.get<dynamic>(
      '${_baseUrl(host, port)}/sync/export',
      options: await _authOptions(),
    );
    final body = response.data is String
        ? response.data as String
        : const JsonEncoder().convert(response.data);
    return SyncChangeset.fromJsonString(body);
  }

  /// Pushes our local export to a remote node.
  Future<PushResult> pushExport(String host, int port, SyncChangeset cs) async {
    final response = await _dio.post<dynamic>(
      '${_baseUrl(host, port)}/sync/import',
      data: cs.toJsonString(),
      options: await _authOptions(extra: {'content-type': 'application/json'}),
    );
    return PushResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Full bidirectional sync with a peer:
  /// 1. Fetch their export → merge into our DB
  /// 2. Push our export → they merge into theirs
  Future<void> syncWith(String host, int port) async {
    final mergeEngine = MergeEngine(
      importService: _importService,
      crdtManager: _crdtManager,
    );

    // Step 1: Pull from remote
    final remote = await fetchExport(host, port);
    await mergeEngine.apply(remote);

    // Step 2: Push to remote
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
    await pushExport(host, port, cs);
  }
}

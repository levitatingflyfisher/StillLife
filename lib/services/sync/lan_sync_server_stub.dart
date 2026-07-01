import '../export/import_service.dart';
import '../export/json_export_service.dart';
import 'crdt_manager.dart';
import 'replay_challenge_store.dart';
import 'sync_codec.dart';

/// Web stub: a browser cannot bind an HTTP server, so LAN sync is
/// native-only. API-compatible with the io implementation.
class LanSyncServer {
  final int _port;

  LanSyncServer({
    required CrdtManager crdtManager,
    required ImportService importService,
    required JsonExportService exportService,
    SyncCodec? codec,
    ReplayChallengeStore? challenges,
    int port = 8420,
  }) : _port = port;

  bool get isRunning => false;

  int get port => _port;

  Future<void> start() async =>
      throw UnsupportedError('LAN sync is not available on web.');

  Future<void> stop() async {}
}

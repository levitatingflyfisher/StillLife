// LAN sync server trio. A browser cannot bind an HTTP server (dart:io /
// shelf_io do not exist there), so LAN sync is native-only by design: the
// real server lives in the io file and the web build gets a stub whose
// start() throws. The sync screen shows a calm "not available on web"
// state instead of offering it.
export 'lan_sync_server_io.dart'
    if (dart.library.js_interop) 'lan_sync_server_stub.dart';

// sqlite3_flutter_libs pulls dart:ffi, which does not compile on the web —
// so the old-Android sqlite3 workaround lives behind this trio. The web
// database runs on sqlite3.wasm and needs no workaround.
export 'sqlite3_workaround_io.dart'
    if (dart.library.js_interop) 'sqlite3_workaround_stub.dart';

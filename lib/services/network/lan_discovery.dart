// mDNS discovery trio. The nsd plugin's Dart code imports dart:io
// unconditionally and browsers cannot speak mDNS anyway, so peer discovery
// is native-only: the real implementation lives in the io file and the web
// build gets a stub that never finds anyone.
export 'lan_discovery_io.dart'
    if (dart.library.js_interop) 'lan_discovery_stub.dart';

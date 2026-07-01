// Ollama mDNS discovery trio. The nsd plugin's Dart code imports dart:io
// unconditionally and browsers cannot speak mDNS, so LAN discovery of
// Ollama hosts is native-only; the web stub discovers nothing (a manually
// entered host URL still works wherever HTTP does).
export 'ollama_host.dart';
export 'ollama_discovery_io.dart'
    if (dart.library.js_interop) 'ollama_discovery_stub.dart';

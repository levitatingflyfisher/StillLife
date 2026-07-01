// Picks the right drift backend at compile time: native sqlite3 (FFI) on
// mobile/desktop, the WASM build in a web worker in the browser.
//
// Same proven pattern as the rest of the OpenHearth fleet (Lullaby et al.).
export 'native.dart' if (dart.library.js_interop) 'web.dart';

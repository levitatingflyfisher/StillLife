/// Platform facade for the on-device AI runtime — the same io/stub trio
/// every native-only integration in this repo uses (OCR backend, frame
/// extractor, share intent). Web gets the stub: unsupported, no engines,
/// and none of the dart:io/FFI plugin imports ever enter the web build.
library;

export 'on_device_support_io.dart'
    if (dart.library.js_interop) 'on_device_support_stub.dart';

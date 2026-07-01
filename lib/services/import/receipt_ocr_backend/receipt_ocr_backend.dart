// Receipt OCR backend trio. google_mlkit_text_recognition (and its commons
// package) import dart:io unconditionally, so the MLKit call sits behind
// this conditional export: real text recognition on Android/iOS, an
// UnsupportedError on the web (callers treat that as "no text found").
export 'receipt_ocr_backend_io.dart'
    if (dart.library.js_interop) 'receipt_ocr_backend_stub.dart';

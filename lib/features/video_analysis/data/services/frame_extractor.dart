// Frame extraction trio. ffmpeg_kit and dart:isolate are native-only, so
// the real extractor lives behind this conditional export; the web stub
// errors immediately (video analysis is not offered on web).
export 'frame_extraction_exception.dart';
export 'frame_extractor_io.dart'
    if (dart.library.js_interop) 'frame_extractor_stub.dart';

// Legacy photo files: before schema v12, photo bytes lived on the filesystem
// under `<documents>/photos/<itemId>/` (with thumbnails under
// `<documents>/thumbnails/<itemId>/`) and the database stored only paths.
// v12 moved the bytes into the database as BLOBs so photos work on the web.
//
// This trio keeps the remaining filesystem duties (reading a legacy file for
// the migration backfill, deleting legacy files so they don't leak disk)
// compile-safe everywhere: real dart:io on native, no-ops on the web (which
// never had photo files).
export 'legacy_photo_files_io.dart'
    if (dart.library.js_interop) 'legacy_photo_files_stub.dart';

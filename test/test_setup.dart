import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';

/// Call this before any database tests to ensure sqlite3 can be loaded
/// on systems where only the versioned `libsqlite3.so.0` is available
/// (e.g. Fedora without sqlite-devel installed).
void ensureSqlite3() {
  if (!Platform.isLinux) return;

  open.overrideFor(OperatingSystem.linux, () {
    // Try the standard unversioned name first, fall back to versioned.
    try {
      return DynamicLibrary.open('libsqlite3.so');
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return DynamicLibrary.open('libsqlite3.so.0');
    }
  });
}

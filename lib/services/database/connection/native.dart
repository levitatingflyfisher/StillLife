import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the production database backed by a native SQLite file.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbDir = await resolveAppDocumentsDir();
    final file = File(p.join(dbDir.path, 'still_life.db'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Opens an in-memory database (tests only).
QueryExecutor openMemoryConnection() => NativeDatabase.memory();

/// Resolves the app documents directory, retrying a few times before giving up.
///
/// On some devices path_provider's platform channel isn't registered the first
/// time it's called right after launch ("Unable to establish connection on
/// channel"). That matters here because drift's [LazyDatabase] caches the FIRST
/// open error for the entire session — so a single transient failure would
/// permanently break every database write (first-run onboarding included) with
/// no recovery short of restarting the app. A short bounded retry lets the
/// channel come up instead of bricking the database.
///
/// [resolve] and [sleep] are injectable for testing; production uses
/// path_provider and a real delay.
Future<Directory> resolveAppDocumentsDir({
  Future<Directory> Function() resolve = getApplicationDocumentsDirectory,
  Future<void> Function(Duration) sleep = _delay,
  int attempts = 5,
  Duration baseDelay = const Duration(milliseconds: 200),
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= attempts; attempt++) {
    try {
      return await resolve();
    } catch (e) {
      lastError = e;
      if (attempt < attempts) await sleep(baseDelay * attempt);
    }
  }
  throw StateError(
    'Could not resolve the app documents directory after $attempts attempts. '
    'Last error: $lastError',
  );
}

Future<void> _delay(Duration d) => Future<void>.delayed(d);

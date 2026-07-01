import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens the production database on the web: loads `sqlite3.wasm` +
/// `drift_worker.js` (both shipped in `web/`) and runs the database off the
/// main thread, persisted to OPFS/IndexedDB depending on browser support.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'still_life',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}

/// In-memory databases are a test-only (VM) affordance.
QueryExecutor openMemoryConnection() =>
    throw UnsupportedError('In-memory database is not supported on the web.');

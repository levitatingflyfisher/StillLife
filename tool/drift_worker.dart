// Entrypoint for the drift web worker. Compiled against THIS repo's pinned
// drift version so the worker protocol always matches (never copy another
// app's drift_worker.js — a version mismatch can corrupt the database):
//
//   dart compile js -O4 -o web/drift_worker.js tool/drift_worker.dart
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/database/database.dart';

/// The global database provider. Override in tests with AppDatabase.memory().
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.production();
  ref.onDispose(() => db.close());
  return db;
});

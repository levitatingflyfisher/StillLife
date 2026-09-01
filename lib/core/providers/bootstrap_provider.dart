import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/inventory/domain/repositories/category_repository.dart';
import '../../features/locations/domain/repositories/room_repository.dart';
import 'repository_providers.dart';
import '../../services/database/database.dart';
import '../sync/seed_rows.dart';
import 'database_provider.dart';

/// Runs once on app start. Seeds default categories and a default
/// property with rooms when the database is empty.
final bootstrapProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    _seedCategoriesIfEmpty(ref.read(categoryRepositoryProvider)),
    _seedPropertyIfEmpty(
      ref.read(databaseProvider),
      ref.read(roomRepositoryProvider),
    ),
  ]);
});

Future<void> _seedCategoriesIfEmpty(CategoryRepository repo) async {
  // Listen once to check if categories exist
  final categories = await repo.watchCategories().first;
  if (categories.isEmpty) {
    await repo.seedDefaults();
  }
}

Future<void> _seedPropertyIfEmpty(
  AppDatabase db,
  RoomRepository roomRepo,
) async {
  final existing = await (db.select(
    db.properties,
  )..where((p) => p.isDeleted.equals(false))).get();
  if (existing.isEmpty) {
    // The first home and its rooms are seeded under stable ids and the
    // seed stamp, so two devices that each start fresh merge into one home
    // (core/sync/seed_rows.dart).
    final propertyId = await seedDefaultHome(db);
    await roomRepo.seedDefaults(propertyId);
  }
}

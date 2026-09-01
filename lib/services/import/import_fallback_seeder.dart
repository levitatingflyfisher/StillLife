import 'package:drift/drift.dart';

import '../database/database.dart';
import '../../core/sync/seed_rows.dart';

/// Ensures the "Imports" category and a default room exist in the database,
/// creating them if necessary.
///
/// Uses SELECT-before-INSERT to remain idempotent — safe to call multiple times.
/// Returns a Dart 3 record `(categoryId, roomId)`.
class ImportFallbackSeeder {
  final AppDatabase _database;

  ImportFallbackSeeder({required AppDatabase database}) : _database = database;

  Future<(String, String)> ensureDefaults() async {
    final categoryId = await _ensureCategory();
    final propertyId = await _ensureProperty();
    final roomId = await _ensureRoom(propertyId);
    return (categoryId, roomId);
  }

  Future<String> _ensureCategory() async {
    final existing =
        await (_database.select(_database.categories)..where(
              (c) => c.name.equals('Imports') & c.isDeleted.equals(false),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    final id = seedId('category', 'Imports');
    final now = DateTime.now();
    await _database
        .into(_database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            name: 'Imports',
            createdAt: now,
            modifiedAt: now,
            nodeId: const Value(seedNodeId),
            hlc: Value(seedHlc),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return id;
  }

  Future<String> _ensureProperty() async {
    final existing =
        await (_database.select(_database.properties)
              ..where((p) => p.isDeleted.equals(false))
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    // The same first home the app seeds on launch (seed_rows.dart).
    return seedDefaultHome(_database);
  }

  Future<String> _ensureRoom(String propertyId) async {
    final existing =
        await (_database.select(_database.rooms)
              ..where(
                (r) =>
                    r.propertyId.equals(propertyId) & r.isDeleted.equals(false),
              )
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    final id = seedId('room', '$propertyId/Home');
    final now = DateTime.now();
    await _database
        .into(_database.rooms)
        .insert(
          RoomsCompanion.insert(
            id: id,
            name: 'Home',
            propertyId: propertyId,
            createdAt: now,
            modifiedAt: now,
            nodeId: const Value(seedNodeId),
            hlc: Value(seedHlc),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return id;
  }
}

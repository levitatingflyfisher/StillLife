import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;
import 'package:still_life/services/import/import_fallback_seeder.dart';

import '../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  late ImportFallbackSeeder seeder;

  setUp(() {
    database = db_pkg.AppDatabase.memory();
    seeder = ImportFallbackSeeder(database: database);
  });
  tearDown(() async => database.close());

  test(
    'creates Imports category and Home property/room from scratch',
    () async {
      final (categoryId, roomId) = await seeder.ensureDefaults();
      expect(categoryId, isNotEmpty);
      expect(roomId, isNotEmpty);

      final categories = await database.select(database.categories).get();
      expect(categories.any((c) => c.name == 'Imports'), isTrue);

      final properties = await database.select(database.properties).get();
      expect(properties.any((p) => p.name == 'Home'), isTrue);

      final rooms = await database.select(database.rooms).get();
      expect(rooms.any((r) => r.name == 'Home'), isTrue);
    },
  );

  test('creates Home property when none exists', () async {
    final (_, roomId) = await seeder.ensureDefaults();
    final properties = await database.select(database.properties).get();
    expect(properties.length, 1);
    expect(properties.first.name, 'Home');
    expect(roomId, isNotEmpty);
  });

  test('is idempotent — second call returns same IDs', () async {
    final (cat1, room1) = await seeder.ensureDefaults();
    final (cat2, room2) = await seeder.ensureDefaults();
    expect(cat1, cat2);
    expect(room1, room2);
  });

  test('reuses existing property when one already exists', () async {
    const propId = 'existing-prop';
    await database
        .into(database.properties)
        .insert(
          db_pkg.PropertiesCompanion.insert(
            id: propId,
            name: 'My House',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
    final (_, roomId) = await seeder.ensureDefaults();
    final rooms = await database.select(database.rooms).get();
    // The room should be under the existing property
    final room = rooms.firstWhere((r) => r.id == roomId);
    expect(room.propertyId, propId);
  });
}

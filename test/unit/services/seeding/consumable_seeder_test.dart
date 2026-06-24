import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;
import 'package:still_life/services/seeding/consumable_seeder.dart';

import '../../../test_setup.dart';

/// Fake FlutterSecureStorage backed by an in-memory map.
class _FakeStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _store[key] = value;
  }
}

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  setUp(() => database = db_pkg.AppDatabase.memory());
  tearDown(() async => database.close());

  Future<void> seedRoom() async {
    await database
        .into(database.properties)
        .insert(
          db_pkg.PropertiesCompanion.insert(
            id: 'p1',
            name: 'Home',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
    await database
        .into(database.rooms)
        .insert(
          db_pkg.RoomsCompanion.insert(
            id: 'r1',
            name: 'Kitchen',
            propertyId: 'p1',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
  }

  test('seedIfNeeded creates Consumables category', () async {
    final storage = _FakeStorage();
    final seeder = ConsumableSeeder(database: database, storage: storage);
    await seeder.seedIfNeeded();
    final cats = await database.select(database.categories).get();
    expect(cats.map((c) => c.name), contains('Consumables'));
  });

  test('seedIfNeeded seeds items when a room exists', () async {
    await seedRoom();
    final storage = _FakeStorage();
    final seeder = ConsumableSeeder(database: database, storage: storage);
    await seeder.seedIfNeeded();
    final items = await database.itemDao.watchAllItems().first;
    expect(items.length, greaterThanOrEqualTo(5));
  });

  test('seedIfNeeded is idempotent — does not double-seed', () async {
    await seedRoom();
    final storage = _FakeStorage();
    final seeder = ConsumableSeeder(database: database, storage: storage);
    await seeder.seedIfNeeded();
    await seeder.seedIfNeeded();
    final cats = await database.select(database.categories).get();
    expect(cats.where((c) => c.name == 'Consumables').length, 1);
  });

  test('seedIfNeeded skips item seeding when no rooms exist', () async {
    final storage = _FakeStorage();
    final seeder = ConsumableSeeder(database: database, storage: storage);
    await seeder.seedIfNeeded();
    final items = await database.itemDao.watchAllItems().first;
    expect(items, isEmpty);
  });
}

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;

  setUp(() => database = db_pkg.AppDatabase.memory());
  tearDown(() async => database.close());

  Future<void> insertProfile({
    required String id,
    required String name,
    bool isDefault = false,
  }) async {
    await database.profileDao.insertProfile(
      db_pkg.ProfilesCompanion.insert(
        id: id,
        name: name,
        isDefault: Value(isDefault),
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026),
      ),
    );
  }

  test('insertProfile + watchProfiles returns non-deleted', () async {
    await insertProfile(id: 'p1', name: 'Alice');
    final profiles = await database.profileDao.watchProfiles().first;
    expect(profiles.length, 1);
    expect(profiles.first.name, 'Alice');
  });

  test('watchProfiles excludes soft-deleted', () async {
    await insertProfile(id: 'p1', name: 'Alice');
    await insertProfile(id: 'p2', name: 'Bob');
    await database.profileDao.softDeleteProfile('p2');
    final profiles = await database.profileDao.watchProfiles().first;
    expect(profiles.length, 1);
    expect(profiles.first.id, 'p1');
  });

  test('setDefault clears previous default and sets new one', () async {
    await insertProfile(id: 'p1', name: 'Alice', isDefault: true);
    await insertProfile(id: 'p2', name: 'Bob');
    await database.profileDao.setDefault('p2');
    final p1 = await database.profileDao.getProfile('p1');
    final p2 = await database.profileDao.getProfile('p2');
    expect(p1!.isDefault, false);
    expect(p2!.isDefault, true);
  });

  test('getProfile returns null for soft-deleted profile', () async {
    await insertProfile(id: 'p1', name: 'Alice');
    await database.profileDao.softDeleteProfile('p1');
    final profile = await database.profileDao.getProfile('p1');
    expect(profile, isNull);
  });

  test('upsertProfile inserts new and updates existing', () async {
    await database.profileDao.upsertProfile(
      db_pkg.ProfilesCompanion.insert(
        id: 'p1',
        name: 'Alice',
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026),
      ),
    );
    // upsert again with updated name
    await database.profileDao.upsertProfile(
      db_pkg.ProfilesCompanion.insert(
        id: 'p1',
        name: 'Alice Updated',
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026, 2),
      ),
    );
    final profile = await database.profileDao.getProfile('p1');
    expect(profile!.name, 'Alice Updated');
  });
}

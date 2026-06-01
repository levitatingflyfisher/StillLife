import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/profiles/data/repositories/profile_repository_impl.dart';
import 'package:still_life/features/profiles/domain/entities/profile.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;

import '../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  late ProfileRepositoryImpl repo;

  setUp(() {
    database = db_pkg.AppDatabase.memory();
    repo = ProfileRepositoryImpl(database);
  });

  tearDown(() async => database.close());

  Profile makeProfile({
    String id = 'p-1',
    String name = 'Alice',
    bool isDefault = false,
  }) => Profile(
    id: id,
    name: name,
    colorHex: '#FF5733',
    avatarEmoji: '🐱',
    isDefault: isDefault,
    createdAt: DateTime(2025),
    modifiedAt: DateTime(2025),
  );

  test('createProfile — returns success and profile is watchable', () async {
    final profile = makeProfile();
    final result = await repo.createProfile(profile);
    result.when(
      success: (created) {
        expect(created.name, 'Alice');
        expect(created.colorHex, '#FF5733');
        expect(created.avatarEmoji, '🐱');
        expect(created.isDefault, isFalse);
      },
      failure: (f) => fail('Expected success, got $f'),
    );

    final profiles = await repo.watchProfiles().first;
    expect(profiles, hasLength(1));
    expect(profiles.first.name, 'Alice');
  });

  test('updateProfile — returns success with updated values', () async {
    final profile = makeProfile();
    await repo.createProfile(profile);

    final updated = profile.copyWith(
      name: 'Alice Updated',
      colorHex: '#0000FF',
    );
    final result = await repo.updateProfile(updated);
    result.when(
      success: (p) {
        expect(p.name, 'Alice Updated');
        expect(p.colorHex, '#0000FF');
      },
      failure: (f) => fail('Expected success, got $f'),
    );

    final profiles = await repo.watchProfiles().first;
    expect(profiles.first.name, 'Alice Updated');
  });

  test(
    'deleteProfile — soft-deletes a non-default profile successfully',
    () async {
      final profile = makeProfile(isDefault: false);
      await repo.createProfile(profile);

      final result = await repo.deleteProfile('p-1');
      result.when(
        success: (_) {},
        failure: (f) => fail('Expected success, got $f'),
      );

      // Profile should no longer appear in watch stream (soft-deleted)
      final profiles = await repo.watchProfiles().first;
      expect(profiles, isEmpty);
    },
  );

  test('deleteProfile — returns failure for the default profile', () async {
    final profile = makeProfile(isDefault: true);
    await repo.createProfile(profile);

    final result = await repo.deleteProfile('p-1');
    result.when(
      success: (_) => fail('Should have returned error for default profile'),
      failure: (f) => expect(f.message, contains('Cannot delete the default')),
    );

    // Profile should still be present
    final profiles = await repo.watchProfiles().first;
    expect(profiles, hasLength(1));
  });

  test('setDefault — transfers default from one profile to another', () async {
    final p1 = makeProfile(id: 'p-1', name: 'Alice', isDefault: true);
    final p2 = makeProfile(id: 'p-2', name: 'Bob', isDefault: false);
    await repo.createProfile(p1);
    await repo.createProfile(p2);

    final result = await repo.setDefault('p-2');
    result.when(
      success: (_) {},
      failure: (f) => fail('Expected success, got $f'),
    );

    final profiles = await repo.watchProfiles().first;
    final alice = profiles.firstWhere((p) => p.id == 'p-1');
    final bob = profiles.firstWhere((p) => p.id == 'p-2');
    expect(alice.isDefault, isFalse);
    expect(bob.isDefault, isTrue);
  });

  test('setDefault — returns failure for non-existent ID', () async {
    final result = await repo.setDefault('non-existent-id');
    result.when(
      success: (_) => fail('Should have returned error for missing profile'),
      failure: (f) => expect(f.message, contains('not found')),
    );
  });

  test('getProfile — returns failure for non-existent ID', () async {
    final result = await repo.getProfile('non-existent-id');
    result.when(
      success: (_) => fail('Should have returned error for missing profile'),
      failure: (f) => expect(f.message, contains('not found')),
    );
  });
}

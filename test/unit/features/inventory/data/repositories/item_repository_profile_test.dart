import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/data/repositories/item_repository_impl.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;
import 'package:still_life/services/storage/photo_storage_service.dart';

import '../../../../../test_setup.dart';

class _FakePhotoStorage extends Fake implements PhotoStorageService {}

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  late ItemRepositoryImpl repo;

  setUp(() {
    database = db_pkg.AppDatabase.memory();
    repo = ItemRepositoryImpl(database, _FakePhotoStorage());
  });

  tearDown(() async => database.close());

  /// Seeds the minimal FK dependencies: one property, one room, one category,
  /// and a profile row for 'p1' (so the FK on Items.creatorProfileId /
  /// ownerProfileId is satisfied).
  Future<void> seedDeps() async {
    await database
        .into(database.properties)
        .insert(
          db_pkg.PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Home',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
    await database
        .into(database.rooms)
        .insert(
          db_pkg.RoomsCompanion.insert(
            id: 'room1',
            name: 'Kitchen',
            propertyId: 'prop1',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
    await database
        .into(database.categories)
        .insert(
          db_pkg.CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Food',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
    // Profile 'p1' — referenced by creatorProfileId / ownerProfileId FK
    await database
        .into(database.profiles)
        .insert(
          db_pkg.ProfilesCompanion.insert(
            id: 'p1',
            name: 'Alice',
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );
  }

  Item makeItem({
    required String id,
    String? creatorProfileId,
    String? ownerProfileId,
  }) => Item(
    id: id,
    name: 'Item $id',
    description: '',
    categoryId: 'cat1',
    roomId: 'room1',
    isInsured: false,
    createdAt: DateTime(2026),
    modifiedAt: DateTime(2026),
    creatorProfileId: creatorProfileId,
    ownerProfileId: ownerProfileId,
  );

  group('Item profile fields', () {
    test('creatorProfileId is persisted and retrieved', () async {
      await seedDeps();
      final item = makeItem(id: 'item-1', creatorProfileId: 'p1');
      final createResult = await repo.createItem(item);
      createResult.when(
        success: (created) => expect(created.creatorProfileId, 'p1'),
        failure: (f) => fail('createItem failed: $f'),
      );

      final fetchResult = await repo.getItem('item-1');
      fetchResult.when(
        success: (fetched) {
          expect(fetched.creatorProfileId, 'p1');
          expect(fetched.ownerProfileId, isNull);
        },
        failure: (f) => fail('getItem failed: $f'),
      );
    });

    test('ownerProfileId is updatable from null to a value', () async {
      await seedDeps();
      // Create without ownerProfileId
      final item = makeItem(id: 'item-2', ownerProfileId: null);
      await repo.createItem(item);

      // Update to set ownerProfileId
      final fetchResult = await repo.getItem('item-2');
      late Item created;
      fetchResult.when(
        success: (c) => created = c,
        failure: (f) => fail('getItem failed: $f'),
      );
      final updated = created.copyWith(ownerProfileId: () => 'p1');
      final updateResult = await repo.updateItem(updated);
      updateResult.when(
        success: (u) => expect(u.ownerProfileId, 'p1'),
        failure: (f) => fail('updateItem failed: $f'),
      );

      final refetch = await repo.getItem('item-2');
      refetch.when(
        success: (fetched) => expect(fetched.ownerProfileId, 'p1'),
        failure: (f) => fail('getItem after update failed: $f'),
      );
    });

    test(
      'profileId filter returns items by creator OR owner (OR logic)',
      () async {
        await seedDeps();

        // Item A — creatorProfileId = 'p1'
        await repo.createItem(makeItem(id: 'item-A', creatorProfileId: 'p1'));
        // Item B — ownerProfileId = 'p1'
        await repo.createItem(makeItem(id: 'item-B', ownerProfileId: 'p1'));
        // Item C — no profile attribution
        await repo.createItem(makeItem(id: 'item-C'));

        final stream = repo.watchItems(const ItemQuery(profileId: 'p1'));
        final results = await stream.first;
        final ids = results.map((i) => i.id).toSet();

        expect(ids, containsAll(['item-A', 'item-B']));
        expect(ids, isNot(contains('item-C')));
        expect(results, hasLength(2));
      },
    );
  });
}

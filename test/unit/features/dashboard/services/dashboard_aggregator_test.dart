import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/dashboard/data/services/dashboard_aggregator.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.memory();
    // Seed FK dependencies.
    final now = DateTime(2025, 1, 1);
    await database
        .into(database.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'prop-1',
            name: 'Home',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await database
        .into(database.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room-kitchen',
            propertyId: 'prop-1',
            name: 'Kitchen',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await database
        .into(database.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room-living',
            propertyId: 'prop-1',
            name: 'Living Room',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await database
        .into(database.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room-office',
            propertyId: 'prop-1',
            name: 'Office',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-food',
            name: 'Food',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-elec',
            name: 'Electronics',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-comp',
            name: 'Computers',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() async => database.close());

  ItemsCompanion item(
    String id,
    String roomId,
    String categoryId, {
    int? currentValueCents,
    int? purchasePriceCents,
    DateTime? purchaseDate,
    bool deleted = false,
  }) {
    final now = DateTime(2025, 1, 1);
    return ItemsCompanion.insert(
      id: id,
      name: 'Item $id',
      categoryId: categoryId,
      roomId: roomId,
      isDeleted: Value(deleted),
      currentValueCents: Value(currentValueCents),
      purchasePriceCents: Value(purchasePriceCents),
      purchaseDate: Value(purchaseDate),
      createdAt: now,
      modifiedAt: now,
    );
  }

  group('DashboardAggregator soft-delete filter', () {
    test('getValueCentsByRoom excludes soft-deleted items', () async {
      await database
          .into(database.items)
          .insert(item('i1', 'room-kitchen', 'cat-food', currentValueCents: 10000));
      await database
          .into(database.items)
          .insert(
            item(
              'i2',
              'room-kitchen',
              'cat-food',
              currentValueCents: 20000,
              deleted: true,
            ),
          );

      final agg = DashboardAggregator(database);
      final result = await agg.getValueCentsByRoom();

      expect(result['Kitchen'], 10000);
    });

    test('getValueCentsByCategory excludes soft-deleted items', () async {
      await database
          .into(database.items)
          .insert(item('i3', 'room-living', 'cat-elec', currentValueCents: 50000));
      await database
          .into(database.items)
          .insert(
            item(
              'i4',
              'room-living',
              'cat-elec',
              currentValueCents: 99900,
              deleted: true,
            ),
          );

      final agg = DashboardAggregator(database);
      final result = await agg.getValueCentsByCategory();

      expect(result['Electronics'], 50000);
    });

    test('getTotalDepreciationCents excludes soft-deleted items', () async {
      final past = DateTime(2022, 1, 1);
      await database
          .into(database.items)
          .insert(
            item(
              'i5',
              'room-office',
              'cat-comp',
              purchasePriceCents: 100000,
              purchaseDate: past,
            ),
          );
      await database
          .into(database.items)
          .insert(
            item(
              'i6',
              'room-office',
              'cat-comp',
              purchasePriceCents: 500000,
              purchaseDate: past,
              deleted: true,
            ),
          );

      final agg = DashboardAggregator(database);
      // Only the active laptop (100000c purchase) should be counted.
      // The deleted one (500000c) must not be included.
      final result = await agg.getTotalDepreciationCents();
      expect(result, lessThan(500000));
      expect(result, greaterThan(0));
    });
  });
}

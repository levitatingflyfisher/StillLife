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
    double? currentValue,
    double? purchasePrice,
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
      currentValue: Value(currentValue),
      purchasePrice: Value(purchasePrice),
      purchaseDate: Value(purchaseDate),
      createdAt: now,
      modifiedAt: now,
    );
  }

  group('DashboardAggregator soft-delete filter', () {
    test('getValueByRoom excludes soft-deleted items', () async {
      await database
          .into(database.items)
          .insert(item('i1', 'room-kitchen', 'cat-food', currentValue: 100.0));
      await database
          .into(database.items)
          .insert(
            item(
              'i2',
              'room-kitchen',
              'cat-food',
              currentValue: 200.0,
              deleted: true,
            ),
          );

      final agg = DashboardAggregator(database);
      final result = await agg.getValueByRoom();

      expect(result['Kitchen'], closeTo(100.0, 0.01));
    });

    test('getValueByCategory excludes soft-deleted items', () async {
      await database
          .into(database.items)
          .insert(item('i3', 'room-living', 'cat-elec', currentValue: 500.0));
      await database
          .into(database.items)
          .insert(
            item(
              'i4',
              'room-living',
              'cat-elec',
              currentValue: 999.0,
              deleted: true,
            ),
          );

      final agg = DashboardAggregator(database);
      final result = await agg.getValueByCategory();

      expect(result['Electronics'], closeTo(500.0, 0.01));
    });

    test('getTotalDepreciation excludes soft-deleted items', () async {
      final past = DateTime(2022, 1, 1);
      await database
          .into(database.items)
          .insert(
            item(
              'i5',
              'room-office',
              'cat-comp',
              purchasePrice: 1000.0,
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
              purchasePrice: 5000.0,
              purchaseDate: past,
              deleted: true,
            ),
          );

      final agg = DashboardAggregator(database);
      // Only the active laptop (1000.0 purchase) should be counted.
      // Deleted one (5000.0) must not be included.
      final result = await agg.getTotalDepreciation();
      expect(result, lessThan(5000.0));
      expect(result, greaterThan(0));
    });
  });
}

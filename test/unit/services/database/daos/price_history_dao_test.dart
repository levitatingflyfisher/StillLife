import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  final now = DateTime(2025, 1, 1);

  setUp(() async {
    db = AppDatabase.memory();
    // Seed required FK rows.
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'p1',
            name: 'Home',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'r1',
            propertyId: 'p1',
            name: 'Living Room',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'c1',
            name: 'Electronics',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'i1',
            name: 'TV',
            categoryId: 'c1',
            roomId: 'r1',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  PriceHistoryEntriesCompanion entry(
    String id,
    double price,
    DateTime recordedAt,
  ) {
    return PriceHistoryEntriesCompanion.insert(
      id: id,
      itemId: 'i1',
      price: price,
      source: 'manual',
      recordedAt: recordedAt,
    );
  }

  group('PriceHistoryDao', () {
    test('watchPriceHistory returns entries ordered newest first', () async {
      await db.priceHistoryDao.insertPriceEntry(
        entry('ph1', 100, DateTime(2025, 1, 1)),
      );
      await db.priceHistoryDao.insertPriceEntry(
        entry('ph2', 200, DateTime(2025, 6, 1)),
      );
      await db.priceHistoryDao.insertPriceEntry(
        entry('ph3', 150, DateTime(2025, 3, 1)),
      );

      final entries = await db.priceHistoryDao.watchPriceHistory('i1').first;
      expect(entries.length, 3);
      // newest first
      expect(entries[0].price, 200);
      expect(entries[1].price, 150);
      expect(entries[2].price, 100);
    });

    test('getLatestPrice returns the most recent entry', () async {
      await db.priceHistoryDao.insertPriceEntry(
        entry('ph1', 100, DateTime(2025, 1, 1)),
      );
      await db.priceHistoryDao.insertPriceEntry(
        entry('ph2', 500, DateTime(2025, 9, 1)),
      );

      final latest = await db.priceHistoryDao.getLatestPrice('i1');
      expect(latest?.price, 500);
    });

    test('getLatestPrice returns null when no entries exist', () async {
      final latest = await db.priceHistoryDao.getLatestPrice('i1');
      expect(latest, isNull);
    });

    test('watchPriceHistory returns empty list for unknown item', () async {
      final entries = await db.priceHistoryDao
          .watchPriceHistory('unknown')
          .first;
      expect(entries, isEmpty);
    });
  });
}

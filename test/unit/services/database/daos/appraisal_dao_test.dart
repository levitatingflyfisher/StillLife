import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  final now = DateTime(2025, 1, 1);

  setUp(() async {
    db = AppDatabase.memory();
    // Seed required rows for FK integrity: property → room → category → item.
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Home',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room1',
            propertyId: 'prop1',
            name: 'Living Room',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Electronics',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'item1',
            name: 'TV',
            categoryId: 'cat1',
            roomId: 'room1',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'item2',
            name: 'Lamp',
            categoryId: 'cat1',
            roomId: 'room1',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  // Helpers
  int msNow() => DateTime.now().millisecondsSinceEpoch;
  int msIn(Duration d) => DateTime.now().add(d).millisecondsSinceEpoch;

  AppraisalsCompanion mkAppraisal(
    String id, {
    String itemId = 'item1',
    String mode = 'resale',
    double value = 100.0,
    String modelKey = 'tv|good',
    String country = 'US',
    int? queriedAt,
    int? expiresAt,
  }) => AppraisalsCompanion.insert(
    id: id,
    itemId: itemId,
    mode: mode,
    value: value,
    itemModelKey: modelKey,
    queriedAt: queriedAt ?? msNow(),
    expiresAt: expiresAt ?? msIn(const Duration(days: 30)),
    countryCode: Value(country),
  );

  group('AppraisalDao.insertAppraisal', () {
    test('inserts a row that can be read back by item', () async {
      await db.appraisalDao.insertAppraisal(mkAppraisal('a1'));
      final list = await db.appraisalDao.watchForItem('item1').first;
      expect(list, hasLength(1));
      expect(list.first.id, 'a1');
    });
  });

  group('AppraisalDao.getLatestByItemAndMode', () {
    test('returns most recent non-expired for the given item + mode', () async {
      await db.appraisalDao.insertAppraisal(
        mkAppraisal(
          'old',
          queriedAt: msIn(const Duration(days: -10)),
          expiresAt: msIn(const Duration(days: 20)),
        ),
      );
      await db.appraisalDao.insertAppraisal(
        mkAppraisal(
          'new',
          queriedAt: msNow(),
          expiresAt: msIn(const Duration(days: 30)),
        ),
      );
      final r = await db.appraisalDao.getLatestByItemAndMode('item1', 'resale');
      expect(r?.id, 'new');
    });

    test('returns null when all rows are expired', () async {
      await db.appraisalDao.insertAppraisal(
        mkAppraisal('expired', expiresAt: msIn(const Duration(days: -1))),
      );
      final r = await db.appraisalDao.getLatestByItemAndMode('item1', 'resale');
      expect(r, isNull);
    });

    test('skips soft-deleted rows', () async {
      await db.appraisalDao.insertAppraisal(mkAppraisal('x'));
      await db.appraisalDao.softDelete('x');
      final r = await db.appraisalDao.getLatestByItemAndMode('item1', 'resale');
      expect(r, isNull);
    });

    test('returns null for wrong mode', () async {
      await db.appraisalDao.insertAppraisal(mkAppraisal('x', mode: 'resale'));
      final r = await db.appraisalDao.getLatestByItemAndMode(
        'item1',
        'replace_new',
      );
      expect(r, isNull);
    });
  });

  group('AppraisalDao.getLatestByCacheKey', () {
    test('returns fresh row matching key regardless of item_id', () async {
      await db.appraisalDao.insertAppraisal(
        mkAppraisal('a1', itemId: 'item2', modelKey: 'tv|good'),
      );
      final r = await db.appraisalDao.getLatestByCacheKey(
        'tv|good',
        'resale',
        'US',
      );
      expect(r?.id, 'a1');
    });

    test('excludes expired rows', () async {
      await db.appraisalDao.insertAppraisal(
        mkAppraisal(
          'old',
          modelKey: 'tv|good',
          expiresAt: msIn(const Duration(days: -1)),
        ),
      );
      final r = await db.appraisalDao.getLatestByCacheKey(
        'tv|good',
        'resale',
        'US',
      );
      expect(r, isNull);
    });

    test('filters by country code', () async {
      await db.appraisalDao.insertAppraisal(
        mkAppraisal('us', modelKey: 'tv|good', country: 'US'),
      );
      final eu = await db.appraisalDao.getLatestByCacheKey(
        'tv|good',
        'resale',
        'DE',
      );
      expect(eu, isNull);
      final us = await db.appraisalDao.getLatestByCacheKey(
        'tv|good',
        'resale',
        'US',
      );
      expect(us?.id, 'us');
    });
  });

  group('AppraisalDao.softDelete', () {
    test('hides row from watchForItem', () async {
      await db.appraisalDao.insertAppraisal(mkAppraisal('a1'));
      await db.appraisalDao.softDelete('a1');
      final list = await db.appraisalDao.watchForItem('item1').first;
      expect(list, isEmpty);
    });
  });

  group('AppraisalDao.softDeleteExpired', () {
    test('soft-deletes expired rows and returns count', () async {
      await db.appraisalDao.insertAppraisal(
        mkAppraisal('stale', expiresAt: msIn(const Duration(days: -1))),
      );
      await db.appraisalDao.insertAppraisal(
        mkAppraisal('fresh', expiresAt: msIn(const Duration(days: 10))),
      );
      final updated = await db.appraisalDao.softDeleteExpired();
      expect(updated, 1);

      // Stale row still in DB but tombstoned (so peers converge).
      final all = await db.select(db.appraisals).get();
      expect(all, hasLength(2));
      final stale = all.firstWhere((r) => r.id == 'stale');
      expect(stale.isDeleted, isTrue);

      // watchForItem hides tombstones.
      final visible = await db.appraisalDao.watchForItem('item1').first;
      expect(visible.map((r) => r.id), ['fresh']);
    });

    test('returns 0 when nothing is expired', () async {
      await db.appraisalDao.insertAppraisal(
        mkAppraisal('fresh', expiresAt: msIn(const Duration(days: 30))),
      );
      final updated = await db.appraisalDao.softDeleteExpired();
      expect(updated, 0);
    });

    test('skips rows already soft-deleted (idempotent)', () async {
      await db.appraisalDao.insertAppraisal(
        mkAppraisal('stale', expiresAt: msIn(const Duration(days: -1))),
      );
      await db.appraisalDao.softDeleteExpired();
      // Second call should find no fresh tombstones to write.
      final second = await db.appraisalDao.softDeleteExpired();
      expect(second, 0);
    });
  });

  group('AppraisalDao.vacuumExpired', () {
    test('hard-deletes tombstones older than grace window', () async {
      // Tombstoned + expired well past the grace window.
      await db.appraisalDao.insertAppraisal(
        mkAppraisal('old-tomb', expiresAt: msIn(const Duration(days: -45))),
      );
      await db.appraisalDao.softDelete('old-tomb');
      // Tombstoned + expired but inside the grace window.
      await db.appraisalDao.insertAppraisal(
        mkAppraisal('young-tomb', expiresAt: msIn(const Duration(days: -5))),
      );
      await db.appraisalDao.softDelete('young-tomb');
      // Live and expired (tombstone not yet stamped).
      await db.appraisalDao.insertAppraisal(
        mkAppraisal('live-expired', expiresAt: msIn(const Duration(days: -45))),
      );

      final removed = await db.appraisalDao.vacuumExpired();
      expect(removed, 1);

      final remaining = (await db.select(db.appraisals).get())
          .map((r) => r.id)
          .toSet();
      expect(remaining, contains('young-tomb'));
      expect(remaining, contains('live-expired'));
      expect(remaining, isNot(contains('old-tomb')));
    });
  });
}

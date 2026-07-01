import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/appraisal/data/repositories/appraisal_repository_impl.dart';
import 'package:still_life/features/appraisal/domain/entities/appraisal.dart';
import 'package:still_life/features/appraisal/domain/entities/appraisal_source.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;

import '../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase db;
  late AppraisalRepositoryImpl repo;
  final now = DateTime(2025, 1, 1);

  setUp(() async {
    db = db_pkg.AppDatabase.memory();
    repo = AppraisalRepositoryImpl(db);

    await db
        .into(db.properties)
        .insert(
          db_pkg.PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Home',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          db_pkg.RoomsCompanion.insert(
            id: 'room1',
            propertyId: 'prop1',
            name: 'Living',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.categories)
        .insert(
          db_pkg.CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Electronics',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.items)
        .insert(
          db_pkg.ItemsCompanion.insert(
            id: 'item1',
            name: 'TV',
            categoryId: 'cat1',
            roomId: 'room1',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  Appraisal buildAppraisal({
    String id = '',
    List<AppraisalSource> sources = const [],
  }) {
    final current = DateTime.now();
    return Appraisal(
      id: id,
      itemId: 'item1',
      mode: AppraisalMode.resale,
      valueCents: 10000,
      currency: 'USD',
      confidence: 0.8,
      sources: sources,
      itemModelKey: 'tv|good',
      countryCode: 'US',
      queriedAt: current,
      expiresAt: current.add(const Duration(days: 30)),
    );
  }

  group('AppraisalRepositoryImpl.save', () {
    test(
      'inserts a new appraisal and assigns a UUID when id is empty',
      () async {
        final r = await repo.save(buildAppraisal());
        r.when(
          success: (saved) {
            expect(saved.id, isNotEmpty);
            expect(saved.itemId, 'item1');
            expect(saved.valueCents, 10000);
          },
          failure: (f) => fail('expected success, got $f'),
        );
      },
    );

    test('whole cents in, whole cents out — the rounding law is structural',
        () async {
      // Fractional dollars can no longer reach a save: valueCents is an int,
      // and the dollars->cents crossing (centsFromDollars) owns the rounding.
      final r = await repo.save(buildAppraisal().copyWith(valueCents: () => 101));
      expect(r.value.valueCents, 101,
          reason: 'the returned entity must match what was written');
      final back = await repo.getLatestByItemAndMode(
        'item1',
        AppraisalMode.resale,
      );
      expect(back?.valueCents, 101,
          reason: 'the database stores the exact cent count');
    });

    test('round-trips sources as JSON', () async {
      final src = [
        const AppraisalSource(
          url: 'https://example.com',
          title: 'Example',
          price: 99.5,
        ),
        const AppraisalSource(url: 'https://b.com', title: 'B'),
      ];
      final r = await repo.save(buildAppraisal(sources: src));
      final saved = r.value;
      final back = await repo.getLatestByItemAndMode(
        'item1',
        AppraisalMode.resale,
      );
      expect(back?.id, saved.id);
      expect(back?.sources.length, 2);
      expect(back?.sources.first.url, 'https://example.com');
      expect(back?.sources.first.price, 99.5);
    });
  });

  group('AppraisalRepositoryImpl.applyToItem', () {
    Appraisal appraisalWith({
      required AppraisalMode mode,
      required int valueCents,
    }) {
      final current = DateTime.now();
      return Appraisal(
        id: 'apply-1',
        itemId: 'item1',
        mode: mode,
        valueCents: valueCents,
        currency: 'USD',
        confidence: 0.9,
        sources: const [],
        itemModelKey: 'tv|good',
        countryCode: 'US',
        queriedAt: current,
        expiresAt: current.add(const Duration(days: 30)),
      );
    }

    Future<db_pkg.Item> item1() => (db.select(db.items)
          ..where((t) => t.id.equals('item1')))
        .getSingle();

    test('resale sets currentValueCents and writes llm_estimate price history',
        () async {
      final r = await repo.applyToItem(
        appraisalWith(mode: AppraisalMode.resale, valueCents: 45000),
      );
      expect(r.isSuccess, isTrue);

      final row = await item1();
      expect(row.currentValueCents, 45000);
      expect(row.replacementCostCents, isNull);

      final history = await db.select(db.priceHistoryEntries).get();
      expect(history, hasLength(1));
      expect(history.single.itemId, 'item1');
      expect(history.single.priceCents, 45000);
      expect(history.single.source, 'llm_estimate');
    });

    test('replace_new sets replacementCostCents and writes NO price history',
        () async {
      final r = await repo.applyToItem(
        appraisalWith(mode: AppraisalMode.replaceNew, valueCents: 79999),
      );
      expect(r.isSuccess, isTrue);

      final row = await item1();
      expect(row.replacementCostCents, 79999);
      expect(row.currentValueCents, isNull);
      expect(await db.select(db.priceHistoryEntries).get(), isEmpty);
    });

    test('replace_equivalent also targets replacementCostCents', () async {
      final r = await repo.applyToItem(
        appraisalWith(mode: AppraisalMode.replaceEquivalent, valueCents: 50000),
      );
      expect(r.isSuccess, isTrue);
      expect((await item1()).replacementCostCents, 50000);
    });

    test('cent counts propagate exactly to the item and the history',
        () async {
      // Decimal rounding (1.005 -> 101, 123.456789 -> 12346) is owned by
      // centsFromDollars at the wire/input boundaries — covered in
      // money_cents_test.dart. From the domain inward, money is an int and
      // must move without any arithmetic at all.
      await repo.applyToItem(
        appraisalWith(mode: AppraisalMode.resale, valueCents: 12346),
      );
      final row = await item1();
      expect(row.currentValueCents, 12346);
      final history = await db.select(db.priceHistoryEntries).get();
      expect(history.single.priceCents, 12346);
    });

    test('fails cleanly for an unknown item', () async {
      final a = Appraisal(
        id: 'apply-x',
        itemId: 'no-such-item',
        mode: AppraisalMode.resale,
        valueCents: 1000,
        currency: 'USD',
        confidence: 0.5,
        sources: const [],
        itemModelKey: 'x|good',
        countryCode: 'US',
        queriedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      final r = await repo.applyToItem(a);
      expect(r.isSuccess, isFalse);
      expect(await db.select(db.priceHistoryEntries).get(), isEmpty);
    });
  });

  group('AppraisalRepositoryImpl.watchForItem', () {
    test('emits stored appraisals newest first', () async {
      final r1 = await repo.save(buildAppraisal());
      final list = await repo.watchForItem('item1').first;
      expect(list, hasLength(1));
      expect(list.first.id, r1.value.id);
    });
  });

  group('AppraisalRepositoryImpl.getLatestByCacheKey', () {
    test('finds stored appraisal by cache key', () async {
      await repo.save(buildAppraisal());
      final found = await repo.getLatestByCacheKey(
        'tv|good',
        AppraisalMode.resale,
        'US',
      );
      expect(found, isNotNull);
      expect(found!.valueCents, 10000);
    });
  });

  group('AppraisalRepositoryImpl.delete', () {
    test('soft-deletes row so watchForItem excludes it', () async {
      final r = await repo.save(buildAppraisal());
      await repo.delete(r.value.id);
      final list = await repo.watchForItem('item1').first;
      expect(list, isEmpty);
    });
  });
}

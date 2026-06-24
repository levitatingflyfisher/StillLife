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
      value: 100,
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
            expect(saved.value, 100);
          },
          failure: (f) => fail('expected success, got $f'),
        );
      },
    );

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
      expect(found!.value, 100);
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

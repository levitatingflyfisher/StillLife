import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/inventory/data/repositories/item_repository_impl.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart'
    as domain;
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/storage/photo_storage_service.dart';

import '../../../../../test_setup.dart';

class _MockPhotoStorage extends Mock implements PhotoStorageService {}

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late ItemRepositoryImpl repo;
  final now = DateTime(2025, 1, 1);

  setUp(() async {
    db = AppDatabase.memory();
    final photoStorage = _MockPhotoStorage();
    when(() => photoStorage.deletePhoto(any())).thenAnswer((_) async {});
    repo = ItemRepositoryImpl(db, photoStorage);
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
  });

  tearDown(() => db.close());

  domain.Item makeItem({double? value}) => domain.Item(
    id: '',
    name: 'TV',
    description: '',
    categoryId: 'c1',
    roomId: 'r1',
    currentValue: value,
    createdAt: now,
    modifiedAt: now,
  );

  group('price history auto-recording', () {
    test('createItem with value records a price history entry', () async {
      final result = await repo.createItem(makeItem(value: 500.0));
      final item = (result as Success<domain.Item>).value;

      final history = await db.priceHistoryDao.watchPriceHistory(item.id).first;
      expect(history.length, 1);
      expect(history.first.price, 500.0);
      expect(history.first.source, 'manual');
    });

    test('createItem without value does not record price history', () async {
      final result = await repo.createItem(makeItem());
      final item = (result as Success<domain.Item>).value;

      final history = await db.priceHistoryDao.watchPriceHistory(item.id).first;
      expect(history, isEmpty);
    });

    test(
      'updateItem with changed value records new price history entry',
      () async {
        final created = await repo.createItem(makeItem(value: 500.0));
        final item = (created as Success<domain.Item>).value;

        await repo.updateItem(item.copyWith(currentValue: () => 400.0));

        final history = await db.priceHistoryDao
            .watchPriceHistory(item.id)
            .first;
        expect(history.length, 2);
        expect(
          history.map((e) => e.price).toSet(),
          containsAll([400.0, 500.0]),
        );
      },
    );

    test(
      'updateItem with same value does not add price history entry',
      () async {
        final created = await repo.createItem(makeItem(value: 500.0));
        final item = (created as Success<domain.Item>).value;

        // Update name only — value unchanged
        await repo.updateItem(item.copyWith(name: 'New TV Name'));

        final history = await db.priceHistoryDao
            .watchPriceHistory(item.id)
            .first;
        expect(history.length, 1);
      },
    );

    test(
      'updateItem with null value does not add price history entry',
      () async {
        final created = await repo.createItem(makeItem());
        final item = (created as Success<domain.Item>).value;

        await repo.updateItem(item.copyWith(name: 'Updated'));

        final history = await db.priceHistoryDao
            .watchPriceHistory(item.id)
            .first;
        expect(history, isEmpty);
      },
    );

    test('deleteItems removes all specified items', () async {
      final r1 = await repo.createItem(makeItem());
      final r2 = await repo.createItem(makeItem());
      final id1 = (r1 as Success<domain.Item>).value.id;
      final id2 = (r2 as Success<domain.Item>).value.id;

      await repo.deleteItems([id1, id2]);

      final remaining = await db.itemDao.countItems();
      expect(remaining, 0);
    });
  });
}

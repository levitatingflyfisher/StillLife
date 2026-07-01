import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/features/inventory/data/repositories/item_repository_impl.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart'
    as domain;
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/storage/photo_storage_service.dart';

import '../../../../../test_setup.dart';

class _MockPhotoStorage extends Mock implements PhotoStorageService {}

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late ItemRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.memory();
    final photoStorage = _MockPhotoStorage();
    when(() => photoStorage.deletePhoto(any())).thenAnswer((_) async {});
    repo = ItemRepositoryImpl(db, photoStorage);

    // Seed a category and room for FK constraints
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Electronics',
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
          ),
        );
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Home',
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room1',
            propertyId: 'prop1',
            name: 'Living Room',
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('ItemRepositoryImpl', () {
    test('createItem inserts and returns item', () async {
      final now = DateTime.now();
      final item = domain.Item(
        id: '',
        name: 'Samsung TV',
        description: '55 inch OLED',
        categoryId: 'cat1',
        roomId: 'room1',
        purchasePriceCents: 120000,
        currentValueCents: 80000,
        replacementCostCents: 130000,
        condition: domain.ItemCondition.good,
        createdAt: now,
        modifiedAt: now,
      );

      final result = await repo.createItem(item);
      expect(result.isSuccess, true);

      final created = result.value;
      expect(created.name, 'Samsung TV');
      expect(created.description, '55 inch OLED');
      expect(created.purchasePriceCents, 120000);
      expect(created.currentValueCents, 80000);
      expect(created.condition, domain.ItemCondition.good);
      expect(created.id, isNotEmpty);
    });

    test('getItem returns item by ID', () async {
      final now = DateTime.now();
      final createResult = await repo.createItem(
        domain.Item(
          id: '',
          name: 'Laptop',
          description: 'MacBook Pro',
          categoryId: 'cat1',
          roomId: 'room1',
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final id = createResult.value.id;
      final getResult = await repo.getItem(id);

      expect(getResult.isSuccess, true);
      expect(getResult.value.name, 'Laptop');
    });

    test('getItem returns failure for non-existent ID', () async {
      final result = await repo.getItem('non-existent');
      expect(result.isFailure, true);
    });

    test('updateItem modifies existing item', () async {
      final now = DateTime.now();
      final createResult = await repo.createItem(
        domain.Item(
          id: '',
          name: 'Chair',
          description: 'Office chair',
          categoryId: 'cat1',
          roomId: 'room1',
          currentValueCents: 20000,
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final created = createResult.value;
      final updated = created.copyWith(
        name: 'Ergonomic Chair',
        currentValueCents: () => 25000,
      );

      final updateResult = await repo.updateItem(updated);
      expect(updateResult.isSuccess, true);
      expect(updateResult.value.name, 'Ergonomic Chair');
      expect(updateResult.value.currentValueCents, 25000);
    });

    test('brand/model/asin round-trip through create and update', () async {
      final now = DateTime.now();
      final createResult = await repo.createItem(
        domain.Item(
          id: '',
          name: 'Headphones',
          description: '',
          categoryId: 'cat1',
          roomId: 'room1',
          brand: 'Sony',
          model: 'WH-1000XM4',
          asin: 'B0863TXGM3',
          createdAt: now,
          modifiedAt: now,
        ),
      );
      expect(createResult.isSuccess, true);
      final created = createResult.value;
      expect(created.brand, 'Sony');
      expect(created.model, 'WH-1000XM4');
      expect(created.asin, 'B0863TXGM3');

      final updateResult = await repo.updateItem(
        created.copyWith(model: () => 'WH-1000XM5'),
      );
      expect(updateResult.isSuccess, true);
      expect(updateResult.value.brand, 'Sony',
          reason: 'update must not drop untouched identity fields');
      expect(updateResult.value.model, 'WH-1000XM5');
      expect(updateResult.value.asin, 'B0863TXGM3');
    });

    test('receiptId round-trips through create and update', () async {
      final now = DateTime.now();
      final createResult = await repo.createItem(
        domain.Item(
          id: '',
          name: 'Coffee Beans',
          description: '',
          categoryId: 'cat1',
          roomId: 'room1',
          receiptId: 'rcpt-1',
          createdAt: now,
          modifiedAt: now,
        ),
      );
      expect(createResult.isSuccess, true);
      final created = createResult.value;
      expect(created.receiptId, 'rcpt-1');

      final updateResult = await repo.updateItem(
        created.copyWith(name: 'Coffee Beans 1kg'),
      );
      expect(updateResult.isSuccess, true);
      expect(updateResult.value.receiptId, 'rcpt-1',
          reason: 'update must not drop the receipt link');
    });

    test('deleteItem removes item', () async {
      final now = DateTime.now();
      final createResult = await repo.createItem(
        domain.Item(
          id: '',
          name: 'Delete Me',
          description: '',
          categoryId: 'cat1',
          roomId: 'room1',
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final id = createResult.value.id;
      final deleteResult = await repo.deleteItem(id);
      expect(deleteResult.isSuccess, true);

      final getResult = await repo.getItem(id);
      expect(getResult.isFailure, true);
    });

    test('watchItems emits items reactively', () async {
      final now = DateTime.now();
      final stream = repo.watchItems(const ItemQuery());

      // First emission should be empty
      await expectLater(stream, emits(isEmpty));

      // Add an item
      await repo.createItem(
        domain.Item(
          id: '',
          name: 'Reactive Item',
          description: '',
          categoryId: 'cat1',
          roomId: 'room1',
          createdAt: now,
          modifiedAt: now,
        ),
      );

      // Second emission should contain the item
      final stream2 = repo.watchItems(const ItemQuery());
      await expectLater(stream2, emits(hasLength(1)));
    });

    test('watchItems filters by room', () async {
      final now = DateTime.now();
      // Add second room
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'room2',
              propertyId: 'prop1',
              name: 'Bedroom',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      await repo.createItem(
        domain.Item(
          id: '',
          name: 'Item in Room 1',
          description: '',
          categoryId: 'cat1',
          roomId: 'room1',
          createdAt: now,
          modifiedAt: now,
        ),
      );
      await repo.createItem(
        domain.Item(
          id: '',
          name: 'Item in Room 2',
          description: '',
          categoryId: 'cat1',
          roomId: 'room2',
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final stream = repo.watchItems(const ItemQuery(roomId: 'room1'));
      await expectLater(stream, emits(hasLength(1)));
    });

    test('moveItems changes room for multiple items', () async {
      final now = DateTime.now();
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'room2',
              propertyId: 'prop1',
              name: 'Bedroom',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      final result1 = await repo.createItem(
        domain.Item(
          id: '',
          name: 'Item A',
          description: '',
          categoryId: 'cat1',
          roomId: 'room1',
          createdAt: now,
          modifiedAt: now,
        ),
      );
      final result2 = await repo.createItem(
        domain.Item(
          id: '',
          name: 'Item B',
          description: '',
          categoryId: 'cat1',
          roomId: 'room1',
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final moveResult = await repo.moveItems([
        result1.value.id,
        result2.value.id,
      ], 'room2');
      expect(moveResult.isSuccess, true);

      final movedA = await repo.getItem(result1.value.id);
      final movedB = await repo.getItem(result2.value.id);
      expect(movedA.value.roomId, 'room2');
      expect(movedB.value.roomId, 'room2');
    });

    test('findByBarcode returns item when barcode matches', () async {
      final now = DateTime.now();
      await repo.createItem(
        domain.Item(
          id: '',
          name: 'Barcode Item',
          description: '',
          categoryId: 'cat1',
          roomId: 'room1',
          barcode: '012345678',
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final found = await repo.findByBarcode('012345678');
      expect(found, isNotNull);
      expect(found!.name, 'Barcode Item');
    });

    test('findByBarcode returns null when barcode not found', () async {
      final result = await repo.findByBarcode('nonexistent-barcode');
      expect(result, isNull);
    });

    test('countItems returns correct count', () async {
      final now = DateTime.now();
      await repo.createItem(
        domain.Item(
          id: '',
          name: 'Item 1',
          description: '',
          categoryId: 'cat1',
          roomId: 'room1',
          createdAt: now,
          modifiedAt: now,
        ),
      );
      await repo.createItem(
        domain.Item(
          id: '',
          name: 'Item 2',
          description: '',
          categoryId: 'cat1',
          roomId: 'room1',
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final result = await repo.countItems(const ItemQuery());
      expect(result.isSuccess, true);
      expect(result.value, 2);
    });
  });
}

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../../../services/storage/photo_storage_service.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';

const _uuid = Uuid();

/// Records a price history snapshot for [itemId] with [value].
Future<void> _recordPrice(
  db.AppDatabase database,
  String itemId,
  double value,
) {
  return database.priceHistoryDao.insertPriceEntry(
    db.PriceHistoryEntriesCompanion.insert(
      id: _uuid.v4(),
      itemId: itemId,
      price: value,
      source: 'manual',
      recordedAt: DateTime.now(),
    ),
  );
}

class ItemRepositoryImpl implements ItemRepository {
  final db.AppDatabase _db;
  final PhotoStorageService _photoStorage;

  ItemRepositoryImpl(this._db, this._photoStorage);

  @override
  Stream<List<Item>> watchItems(ItemQuery query) {
    return _db.itemDao
        .watchAllItems(
          roomId: query.roomId,
          categoryId: query.categoryId,
          containerId: query.containerId,
          condition: query.condition?.label,
          minValue: query.minValue,
          maxValue: query.maxValue,
          priceField: query.priceField.name,
          addedAfter: query.addedAfter,
          addedBefore: query.addedBefore,
          hasPhoto: query.hasPhoto,
          hasReceipt: query.hasReceipt,
          hasBarcode: query.hasBarcode,
          profileId: query.profileId,
          sortBy: query.sortBy.name,
          ascending: query.ascending,
          limit: query.limit,
          offset: query.offset,
        )
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Stream<Item?> watchItem(String id) {
    final query = _db.select(_db.items)
      ..where((t) => t.id.equals(id) & t.isDeleted.equals(false));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _mapToEntity(row),
    );
  }

  @override
  Future<Result<Item>> getItem(String id) async {
    try {
      final row = await _db.itemDao.getItemById(id);
      if (row == null) {
        return const Err(DatabaseFailure('Item not found'));
      }
      return Success(_mapToEntity(row));
    } catch (e) {
      return Err(DatabaseFailure('Failed to get item: $e'));
    }
  }

  @override
  Future<Result<Item>> createItem(Item item) async {
    try {
      final now = DateTime.now();
      final id = item.id.isEmpty ? _uuid.v4() : item.id;
      final companion = db.ItemsCompanion.insert(
        id: id,
        name: item.name,
        description: Value(item.description),
        categoryId: item.categoryId,
        roomId: item.roomId,
        purchaseDate: Value(item.purchaseDate),
        purchasePrice: Value(item.purchasePrice),
        currentValue: Value(item.currentValue),
        replacementCost: Value(item.replacementCost),
        condition: Value(item.condition?.label),
        serialNumber: Value(item.serialNumber),
        warrantyExpiration: Value(item.warrantyExpiration),
        containerId: Value(item.containerId),
        creatorProfileId: Value(item.creatorProfileId),
        ownerProfileId: Value(item.ownerProfileId),
        barcode: Value(item.barcode),
        storeUrl: Value(item.storeUrl),
        notes: Value(item.notes),
        isInsured: Value(item.isInsured),
        quantity: Value(item.quantity),
        quantityUnit: Value(item.quantityUnit),
        lowStockThreshold: Value(item.lowStockThreshold),
        createdAt: now,
        modifiedAt: now,
      );
      await _db.itemDao.insertItem(companion);
      if (item.currentValue != null) {
        await _recordPrice(_db, id, item.currentValue!);
      }
      return getItem(id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to create item: $e'));
    }
  }

  @override
  Future<Result<Item>> updateItem(Item item) async {
    try {
      // Record price history when value changes.
      final existing = await _db.itemDao.getItemById(item.id);
      if (item.currentValue != null &&
          item.currentValue != existing?.currentValue) {
        await _recordPrice(_db, item.id, item.currentValue!);
      }

      final companion = db.ItemsCompanion(
        id: Value(item.id),
        name: Value(item.name),
        description: Value(item.description),
        categoryId: Value(item.categoryId),
        roomId: Value(item.roomId),
        purchaseDate: Value(item.purchaseDate),
        purchasePrice: Value(item.purchasePrice),
        currentValue: Value(item.currentValue),
        replacementCost: Value(item.replacementCost),
        condition: Value(item.condition?.label),
        serialNumber: Value(item.serialNumber),
        warrantyExpiration: Value(item.warrantyExpiration),
        containerId: Value(item.containerId),
        creatorProfileId: Value(item.creatorProfileId),
        ownerProfileId: Value(item.ownerProfileId),
        barcode: Value(item.barcode),
        storeUrl: Value(item.storeUrl),
        notes: Value(item.notes),
        isInsured: Value(item.isInsured),
        quantity: Value(item.quantity),
        quantityUnit: Value(item.quantityUnit),
        lowStockThreshold: Value(item.lowStockThreshold),
        modifiedAt: Value(DateTime.now()),
      );
      await _db.itemDao.updateItem(companion);
      return getItem(item.id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to update item: $e'));
    }
  }

  @override
  Future<Result<void>> deleteItem(String id) async {
    try {
      // Delete photo files from disk before soft-deleting the DB rows.
      final paths = await _db.photoDao.getPhotoFilePathsForItem(id);
      for (final path in paths) {
        await _photoStorage.deletePhoto(path);
      }
      await _db.itemDao.deleteItem(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete item: $e'));
    }
  }

  @override
  Future<Result<void>> deleteItems(List<String> itemIds) async {
    try {
      for (final id in itemIds) {
        final paths = await _db.photoDao.getPhotoFilePathsForItem(id);
        for (final path in paths) {
          await _photoStorage.deletePhoto(path);
        }
      }
      await _db.itemDao.deleteItems(itemIds);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete items: $e'));
    }
  }

  @override
  Future<Result<void>> moveItems(List<String> itemIds, String newRoomId) async {
    try {
      await _db.itemDao.moveItemsToRoom(itemIds, newRoomId);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to move items: $e'));
    }
  }

  @override
  Future<Result<int>> countItems(ItemQuery query) async {
    try {
      final count = await _db.itemDao.countItems(
        roomId: query.roomId,
        categoryId: query.categoryId,
      );
      return Success(count);
    } catch (e) {
      return Err(DatabaseFailure('Failed to count items: $e'));
    }
  }

  @override
  Stream<List<Item>> searchItems(String query) {
    return _db.itemDao
        .searchItems(query)
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<Item?> findByBarcode(String barcode) async {
    final row = await _db.itemDao.getItemByBarcode(barcode);
    return row == null ? null : _mapToEntity(row);
  }

  Item _mapToEntity(db.Item row) {
    return Item(
      id: row.id,
      name: row.name,
      description: row.description,
      categoryId: row.categoryId,
      roomId: row.roomId,
      purchaseDate: row.purchaseDate,
      purchasePrice: row.purchasePrice,
      currentValue: row.currentValue,
      replacementCost: row.replacementCost,
      condition: ItemCondition.fromString(row.condition),
      serialNumber: row.serialNumber,
      warrantyExpiration: row.warrantyExpiration,
      containerId: row.containerId,
      creatorProfileId: row.creatorProfileId,
      ownerProfileId: row.ownerProfileId,
      barcode: row.barcode,
      storeUrl: row.storeUrl,
      notes: row.notes,
      isInsured: row.isInsured,
      createdAt: row.createdAt,
      modifiedAt: row.modifiedAt,
      quantity: row.quantity,
      quantityUnit: row.quantityUnit,
      lowStockThreshold: row.lowStockThreshold,
    );
  }

  @override
  Stream<List<Item>> watchLowStockItems() {
    return _db.itemDao.watchLowStockItems().map(
      (rows) => rows.map(_mapToEntity).toList(),
    );
  }

  @override
  Future<Result<Item>> decrementQuantity(String id) async {
    try {
      await _db.itemDao.decrementQuantity(id);
      return getItem(id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to decrement quantity: $e'));
    }
  }
}

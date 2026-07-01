import '../../../../core/errors/result.dart';
import '../entities/item.dart';

/// Which price field the value-range filter applies to.
enum PriceField { purchasePriceCents, currentValueCents, replacementCostCents }

/// Filter/sort criteria for querying items.
class ItemQuery {
  final String? searchText;
  final String? roomId;
  final String? categoryId;
  final String? containerId;
  final List<String>? tagIds;
  final ItemCondition? condition;
  final int? minValueCents;
  final int? maxValueCents;
  final PriceField priceField;
  final DateTime? addedAfter;
  final DateTime? addedBefore;
  final bool? hasPhoto;
  final bool? hasReceipt;
  final bool? hasBarcode;
  final String? profileId; // filters creatorProfileId = ? OR ownerProfileId = ?
  final ItemSortField sortBy;
  final bool ascending;
  final int? limit;
  final int? offset;

  const ItemQuery({
    this.searchText,
    this.roomId,
    this.categoryId,
    this.containerId,
    this.tagIds,
    this.condition,
    this.minValueCents,
    this.maxValueCents,
    this.priceField = PriceField.currentValueCents,
    this.addedAfter,
    this.addedBefore,
    this.hasPhoto,
    this.hasReceipt,
    this.hasBarcode,
    this.profileId,
    this.sortBy = ItemSortField.name,
    this.ascending = true,
    this.limit,
    this.offset,
  });

  ItemQuery copyWith({
    // Note: pre-existing nullable fields use the simple T? pattern (null = keep existing).
    // Only profileId (and any future nullable fields) use the Function()? lambda pattern
    // which allows callers to explicitly set a field back to null via () => null.
    // TODO: migrate all nullable fields to the lambda pattern in a future refactor.
    String? searchText,
    String? roomId,
    String? categoryId,
    String? containerId,
    List<String>? tagIds,
    ItemCondition? condition,
    int? minValueCents,
    int? maxValueCents,
    PriceField? priceField,
    DateTime? addedAfter,
    DateTime? addedBefore,
    bool? hasPhoto,
    bool? hasReceipt,
    bool? hasBarcode,
    String? Function()? profileId,
    ItemSortField? sortBy,
    bool? ascending,
    int? limit,
    int? offset,
  }) {
    return ItemQuery(
      searchText: searchText ?? this.searchText,
      roomId: roomId ?? this.roomId,
      categoryId: categoryId ?? this.categoryId,
      containerId: containerId ?? this.containerId,
      tagIds: tagIds ?? this.tagIds,
      condition: condition ?? this.condition,
      minValueCents: minValueCents ?? this.minValueCents,
      maxValueCents: maxValueCents ?? this.maxValueCents,
      priceField: priceField ?? this.priceField,
      addedAfter: addedAfter ?? this.addedAfter,
      addedBefore: addedBefore ?? this.addedBefore,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      hasReceipt: hasReceipt ?? this.hasReceipt,
      hasBarcode: hasBarcode ?? this.hasBarcode,
      profileId: profileId != null ? profileId() : this.profileId,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

enum ItemSortField {
  name,
  currentValueCents,
  replacementCostCents,
  createdAt,
  purchaseDate,
}

abstract class ItemRepository {
  /// Watch all items matching a query (reactive stream).
  Stream<List<Item>> watchItems(ItemQuery query);

  /// Get a single item by ID.
  Future<Result<Item>> getItem(String id);

  /// Watch a single item by ID. Emits null if the item is missing or
  /// soft-deleted. Used by detail screens so they refresh after edits.
  Stream<Item?> watchItem(String id);

  /// Create a new item.
  /// [priceSource] is the provenance recorded with the automatic
  /// price-history entry when [Item.currentValueCents] is set — 'manual' for
  /// user-typed values, 'llm_estimate' for AI-suggested ones (see
  /// PriceHistoryEntries.source vocabulary in tables.dart).
  Future<Result<Item>> createItem(Item item, {String priceSource});

  /// Update an existing item.
  Future<Result<Item>> updateItem(Item item);

  /// Delete an item by ID.
  Future<Result<void>> deleteItem(String id);

  /// Bulk move items to a different room.
  Future<Result<void>> moveItems(List<String> itemIds, String newRoomId);

  /// Bulk delete items.
  Future<Result<void>> deleteItems(List<String> itemIds);

  /// Get total count matching a query.
  Future<Result<int>> countItems(ItemQuery query);

  /// Full-text search.
  Stream<List<Item>> searchItems(String query);

  /// Find an item by its barcode value. Returns null if not in inventory.
  Future<Item?> findByBarcode(String barcode);

  /// Watch all items where quantity is set and at or below lowStockThreshold.
  Stream<List<Item>> watchLowStockItems();

  /// Decrement this item's quantity by 1 (floor 0). No-op if quantity is null.
  /// Returns the updated item.
  Future<Result<Item>> decrementQuantity(String id);
}

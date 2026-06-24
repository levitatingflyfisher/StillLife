import 'package:drift/drift.dart';

import '../../features/inventory/domain/entities/item.dart';
import '../database/database.dart' as db_pkg;

/// Returns the top-N highest-value items with no insurance coverage.
/// Coverage is determined by `items.is_insured = 0` (the existing boolean
/// column). Soft-deleted items are excluded. Items with no `currentValue`
/// are excluded — we can't rank them.
class InsuranceGapService {
  final db_pkg.AppDatabase _db;
  InsuranceGapService(this._db);

  Future<List<Item>> topUncovered({int limit = 10, double minValue = 0}) async {
    final q = _db.select(_db.items)
      ..where((t) => t.isDeleted.equals(false))
      ..where((t) => t.isInsured.equals(false))
      ..where((t) => t.currentValue.isNotNull())
      ..where((t) => t.currentValue.isBiggerOrEqualValue(minValue))
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.currentValue, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    final rows = await q.get();
    return rows.map(_map).toList(growable: false);
  }

  Item _map(db_pkg.Item r) => Item(
    id: r.id,
    name: r.name,
    description: r.description,
    categoryId: r.categoryId,
    roomId: r.roomId,
    purchaseDate: r.purchaseDate,
    purchasePrice: r.purchasePrice,
    currentValue: r.currentValue,
    replacementCost: r.replacementCost,
    condition: ItemCondition.fromString(r.condition),
    serialNumber: r.serialNumber,
    warrantyExpiration: r.warrantyExpiration,
    barcode: r.barcode,
    storeUrl: r.storeUrl,
    notes: r.notes,
    isInsured: r.isInsured,
    containerId: r.containerId,
    creatorProfileId: r.creatorProfileId,
    ownerProfileId: r.ownerProfileId,
    quantity: r.quantity,
    quantityUnit: r.quantityUnit,
    lowStockThreshold: r.lowStockThreshold,
    createdAt: r.createdAt,
    modifiedAt: r.modifiedAt,
  );
}

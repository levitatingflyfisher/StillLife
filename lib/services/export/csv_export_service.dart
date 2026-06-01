import 'package:drift/drift.dart';

import '../../core/utils/label_id.dart';
import '../database/database.dart';

/// Exports the inventory as an RFC-4180-compliant CSV string.
///
/// All fields are quoted so values with commas or newlines are safe.
/// Soft-deleted items are excluded.
class CsvExportService {
  final AppDatabase _db;

  CsvExportService(this._db);

  static const _headers = [
    'Name',
    'Description',
    'Category',
    'Room',
    'Container',
    'Condition',
    'Purchase Price',
    'Current Value',
    'Replacement Cost',
    'Quantity',
    'Unit',
    'Low Stock Threshold',
    'Purchase Date',
    'Warranty Expiry',
    'Serial Number',
    'Barcode',
    'Label ID',
    'Notes',
    'Insured',
    'Tags',
    'Date Added',
    'Appraisal Resale',
    'Appraisal Replace New',
    'Appraisal Replace Equivalent',
  ];

  Future<String> exportItemsToCsv() async {
    // Items joined with category / room / container names.
    final query =
        _db.select(_db.items).join([
            leftOuterJoin(
              _db.categories,
              _db.categories.id.equalsExp(_db.items.categoryId),
            ),
            leftOuterJoin(_db.rooms, _db.rooms.id.equalsExp(_db.items.roomId)),
            leftOuterJoin(
              _db.storageContainers,
              _db.storageContainers.id.equalsExp(_db.items.containerId),
            ),
          ])
          ..where(_db.items.isDeleted.equals(false))
          ..orderBy([OrderingTerm.asc(_db.items.name)]);

    final rows = await query.get();

    // itemId → semicolon-separated tag names
    final tagMap = await _buildTagMap();
    // itemId → (mode wire) → most-recent non-deleted value
    final apprMap = await _buildAppraisalMap();

    final buf = StringBuffer();
    buf.writeln(_headers.map(_q).join(','));

    for (final row in rows) {
      final item = row.readTable(_db.items);
      final cat = row.readTableOrNull(_db.categories)?.name ?? '';
      final room = row.readTableOrNull(_db.rooms)?.name ?? '';
      final container = row.readTableOrNull(_db.storageContainers)?.name ?? '';
      final tags = tagMap[item.id] ?? '';
      final byMode = apprMap[item.id] ?? const {};

      buf.writeln(
        [
          _q(item.name),
          _q(item.description),
          _q(cat),
          _q(room),
          _q(container),
          _q(item.condition),
          _q(item.purchasePrice?.toStringAsFixed(2)),
          _q(item.currentValue?.toStringAsFixed(2)),
          _q(item.replacementCost?.toStringAsFixed(2)),
          _q(item.quantity?.toString()),
          _q(item.quantityUnit),
          _q(item.lowStockThreshold?.toString()),
          _q(item.purchaseDate?.toIso8601String().substring(0, 10)),
          _q(item.warrantyExpiration?.toIso8601String().substring(0, 10)),
          _q(item.serialNumber),
          _q(item.barcode),
          _q(labelId(item.id)),
          _q(item.notes),
          _q(item.isInsured ? 'Yes' : 'No'),
          _q(tags),
          _q(item.createdAt.toIso8601String().substring(0, 10)),
          _q(byMode['resale']?.toStringAsFixed(2)),
          _q(byMode['replace_new']?.toStringAsFixed(2)),
          _q(byMode['replace_equivalent']?.toStringAsFixed(2)),
        ].join(','),
      );
    }

    return buf.toString();
  }

  /// For each item, the most recent non-deleted appraisal per mode.
  Future<Map<String, Map<String, double>>> _buildAppraisalMap() async {
    final rows =
        await (_db.select(_db.appraisals)
              ..where((t) => t.isDeleted.equals(false))
              ..orderBy([(t) => OrderingTerm.desc(t.queriedAt)]))
            .get();
    final map = <String, Map<String, double>>{};
    for (final r in rows) {
      final byMode = map.putIfAbsent(r.itemId, () => {});
      byMode.putIfAbsent(r.mode, () => r.value);
    }
    return map;
  }

  Future<Map<String, String>> _buildTagMap() async {
    // Filter both sides of the join: a soft-deleted itemTag (junction
    // tombstone) or a soft-deleted tag (renamed/retired) must not leak into
    // the CSV. Without this, removed tags would resurface on every export.
    final rows =
        await (_db.select(
          _db.itemTags,
        )..where((it) => it.isDeleted.equals(false))).join([
          innerJoin(
            _db.tags,
            _db.tags.id.equalsExp(_db.itemTags.tagId) &
                _db.tags.isDeleted.equals(false),
          ),
        ]).get();

    final map = <String, List<String>>{};
    for (final row in rows) {
      final it = row.readTable(_db.itemTags);
      final tag = row.readTable(_db.tags);
      map.putIfAbsent(it.itemId, () => []).add(tag.name);
    }
    return map.map((k, v) => MapEntry(k, v.join('; ')));
  }

  /// Exports low-stock items as a simple shopping-list CSV.
  ///
  /// Columns: Name, Quantity, Unit, Low Stock Threshold, Category, Room.
  Future<String> exportShoppingListToCsv() async {
    const headers = [
      'Name',
      'Quantity',
      'Unit',
      'Low Stock Threshold',
      'Category',
      'Room',
    ];

    final query =
        _db.select(_db.items).join([
            leftOuterJoin(
              _db.categories,
              _db.categories.id.equalsExp(_db.items.categoryId),
            ),
            leftOuterJoin(_db.rooms, _db.rooms.id.equalsExp(_db.items.roomId)),
          ])
          ..where(_db.items.isDeleted.equals(false))
          ..where(_db.items.quantity.isNotNull())
          ..where(_db.items.lowStockThreshold.isNotNull())
          ..orderBy([OrderingTerm.asc(_db.items.name)]);

    final rows = await query.get();

    final buf = StringBuffer();
    buf.writeln(headers.map(_q).join(','));

    for (final row in rows) {
      final item = row.readTable(_db.items);
      if (item.quantity == null || item.lowStockThreshold == null) continue;
      if (item.quantity! > item.lowStockThreshold!) continue;

      final cat = row.readTableOrNull(_db.categories)?.name ?? '';
      final room = row.readTableOrNull(_db.rooms)?.name ?? '';

      buf.writeln(
        [
          _q(item.name),
          _q(item.quantity?.toStringAsFixed(1)),
          _q(item.quantityUnit),
          _q(item.lowStockThreshold?.toStringAsFixed(1)),
          _q(cat),
          _q(room),
        ].join(','),
      );
    }

    return buf.toString();
  }

  /// Wraps [value] in double-quotes and escapes embedded double-quotes.
  static String _q(Object? value) {
    final s = value?.toString() ?? '';
    return '"${s.replaceAll('"', '""')}"';
  }
}

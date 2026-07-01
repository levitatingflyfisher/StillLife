import 'package:drift/drift.dart';

import '../../../../services/database/database.dart';
import 'depreciation_calculator.dart';

/// Aggregates dashboard metrics from the database.
class DashboardAggregator {
  final AppDatabase _db;
  final DepreciationCalculator _calculator;

  DashboardAggregator(this._db, [DepreciationCalculator? calculator])
    : _calculator = calculator ?? DepreciationCalculator();

  /// Returns the top [limit] items sorted by current value descending.
  ///
  /// Each entry is a record of (item name, current value in cents).
  Future<List<({String name, int valueCents})>> getTopItemsByValue(
    int limit,
  ) async {
    final query = _db.selectOnly(_db.items)
      ..addColumns([_db.items.name, _db.items.currentValueCents])
      ..where(_db.items.currentValueCents.isNotNull())
      ..orderBy([
        OrderingTerm(
          expression: _db.items.currentValueCents,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((row) {
      return (
        name: row.read(_db.items.name)!,
        valueCents: row.read(_db.items.currentValueCents) ?? 0,
      );
    }).toList();
  }

  /// Returns cent totals grouped by room name (via JOIN with Rooms table).
  Future<Map<String, int>> getValueCentsByRoom() async {
    final sumExpr = _db.items.currentValueCents.sum();
    final query =
        _db.selectOnly(_db.items).join([
            innerJoin(_db.rooms, _db.rooms.id.equalsExp(_db.items.roomId)),
          ])
          ..addColumns([_db.rooms.name, sumExpr])
          ..where(_db.items.isDeleted.equals(false))
          ..groupBy([_db.rooms.name]);

    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(_db.rooms.name)!: row.read(sumExpr) ?? 0,
    };
  }

  /// Returns cent totals grouped by category name (via JOIN with Categories).
  Future<Map<String, int>> getValueCentsByCategory() async {
    final sumExpr = _db.items.currentValueCents.sum();
    final query =
        _db.selectOnly(_db.items).join([
            innerJoin(
              _db.categories,
              _db.categories.id.equalsExp(_db.items.categoryId),
            ),
          ])
          ..addColumns([_db.categories.name, sumExpr])
          ..where(_db.items.isDeleted.equals(false))
          ..groupBy([_db.categories.name]);

    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(_db.categories.name)!: row.read(sumExpr) ?? 0,
    };
  }

  /// Returns the [limit] most recently modified items (for Recent Activity widget).
  Future<List<({String id, String name, DateTime modifiedAt})>>
  getRecentActivity({int limit = 5}) async {
    final query = _db.select(_db.items)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)])
      ..limit(limit);
    final rows = await query.get();
    return rows
        .map((r) => (id: r.id, name: r.name, modifiedAt: r.modifiedAt))
        .toList();
  }

  /// Returns item counts grouped by month (last 6 months), oldest first.
  Future<List<({String label, int count})>> getItemsByMonth() async {
    final now = DateTime.now();
    final results = <({String label, int count})>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final start = DateTime(month.year, month.month);
      final end = DateTime(month.year, month.month + 1);
      final countExpr = _db.items.id.count();
      final query = _db.selectOnly(_db.items)
        ..addColumns([countExpr])
        ..where(_db.items.createdAt.isBiggerOrEqualValue(start))
        ..where(_db.items.createdAt.isSmallerThanValue(end))
        ..where(_db.items.isDeleted.equals(false));
      final row = await query.getSingle();
      results.add((
        label: '${_monthAbbr(month.month)} ${month.year % 100}',
        count: row.read(countExpr) ?? 0,
      ));
    }
    return results;
  }

  static String _monthAbbr(int month) {
    const abbr = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return abbr[month];
  }

  /// Sums depreciation in cents across all items that have both purchase
  /// price and date. The calculator's straight-line math is unit-agnostic,
  /// so feeding cents yields cents.
  Future<int> getTotalDepreciationCents() async {
    final query = _db.select(_db.items)
      ..where(
        (t) =>
            t.purchasePriceCents.isNotNull() &
            t.purchaseDate.isNotNull() &
            t.isDeleted.equals(false),
      );

    final items = await query.get();

    // Look up category names for each item.
    double totalDepreciation = 0.0;
    for (final item in items) {
      final category = await (_db.select(
        _db.categories,
      )..where((c) => c.id.equals(item.categoryId))).getSingleOrNull();
      final categoryName = category?.name ?? 'Other';

      final info = _calculator.calculateDepreciation(
        item.purchasePriceCents!.toDouble(),
        item.purchaseDate!,
        categoryName,
      );
      totalDepreciation += info.totalDepreciation;
    }

    return totalDepreciation.round();
  }
}

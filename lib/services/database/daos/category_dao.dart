import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories, Items])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<Category>> watchAllCategories() {
    return (select(categories)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<Category?> getCategoryById(String id) {
    return (select(categories)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> insertCategory(
    CategoriesCompanion entry, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await into(categories).insert(entry);
  }

  Future<bool> updateCategory(
    CategoriesCompanion entry, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return (update(categories)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Soft-delete a category.
  ///
  /// When [crdt] is provided, stamps `nodeId`/`hlc` on the tombstone so the
  /// CRDT merge engine can propagate it to peers.
  Future<void> deleteCategory(String id, {CrdtManager? crdt}) async {
    var entry = CategoriesCompanion(
      id: Value(id),
      isDeleted: const Value(true),
      modifiedAt: Value(DateTime.now()),
    );
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await (update(categories)..where((t) => t.id.equals(id))).write(entry);
  }

  /// Insert all default categories if none exist.
  Future<void> seedDefaults(List<CategoriesCompanion> defaults) async {
    final count =
        await (selectOnly(categories)..addColumns([categories.id.count()]))
            .getSingle()
            .then((row) => row.read(categories.id.count()));

    if ((count ?? 0) == 0) {
      await batch((batch) {
        batch.insertAll(categories, defaults);
      });
    }
  }

  /// Get item count per category (excludes soft-deleted items).
  Future<Map<String, int>> getCategoryItemCounts() async {
    final countExpr = items.id.count();
    final query = selectOnly(items)
      ..addColumns([items.categoryId, countExpr])
      ..where(items.isDeleted.equals(false))
      ..groupBy([items.categoryId]);
    final results = await query.get();
    return {
      for (final row in results)
        row.read(items.categoryId)!: row.read(countExpr) ?? 0,
    };
  }
}

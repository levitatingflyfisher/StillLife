import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../../../core/sync/sync_stamp.dart';
import '../../../../core/sync/seed_rows.dart';

const _uuid = Uuid();

class CategoryRepositoryImpl implements CategoryRepository {
  final db.AppDatabase _db;

  CategoryRepositoryImpl(this._db, {SyncStamp stamp = SyncStamp.none})
    : _stamp = stamp;

  /// Gives every write its sync stamp (see [SyncStamp]).
  final SyncStamp _stamp;

  @override
  Stream<List<Category>> watchCategories() {
    return _db.categoryDao.watchAllCategories().map(
      (rows) => rows.map(_mapToEntity).toList(),
    );
  }

  @override
  Future<Result<Category>> getCategory(String id) async {
    try {
      final row = await _db.categoryDao.getCategoryById(id);
      if (row == null) {
        return const Err(DatabaseFailure('Category not found'));
      }
      return Success(_mapToEntity(row));
    } catch (e) {
      return Err(DatabaseFailure('Failed to get category: $e'));
    }
  }

  @override
  Future<Result<Category>> createCategory(Category category) async {
    try {
      final now = DateTime.now();
      final id = category.id.isEmpty ? _uuid.v4() : category.id;
      final companion = db.CategoriesCompanion.insert(
        id: id,
        name: category.name,
        parentId: Value(category.parentId),
        iconCodePoint: Value(category.iconCodePoint),
        createdAt: now,
        modifiedAt: now,
      );
      await _stamp.write(
        (c) => _db.categoryDao.insertCategory(companion, crdt: c),
      );
      return getCategory(id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to create category: $e'));
    }
  }

  @override
  Future<Result<Category>> updateCategory(Category category) async {
    try {
      final companion = db.CategoriesCompanion(
        id: Value(category.id),
        name: Value(category.name),
        parentId: Value(category.parentId),
        iconCodePoint: Value(category.iconCodePoint),
        modifiedAt: Value(DateTime.now()),
      );
      await _stamp.write(
        (c) => _db.categoryDao.updateCategory(companion, crdt: c),
      );
      return getCategory(category.id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to update category: $e'));
    }
  }

  @override
  Future<Result<void>> deleteCategory(String id) async {
    try {
      await _stamp.write((c) => _db.categoryDao.deleteCategory(id, crdt: c));
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete category: $e'));
    }
  }

  @override
  Future<Result<void>> seedDefaults() async {
    try {
      final now = DateTime.now();
      final defaults = AppConstants.defaultCategories.map((name) {
        // Seeded rows sync as the same row everywhere (see seed_rows.dart).
        return db.CategoriesCompanion.insert(
          id: seedId('category', name),
          name: name,
          iconCodePoint: Value(AppConstants.categoryIcons[name]),
          createdAt: now,
          modifiedAt: now,
          nodeId: const Value(seedNodeId),
          hlc: Value(seedHlc),
        );
      }).toList();
      await _db.categoryDao.seedDefaults(defaults);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to seed categories: $e'));
    }
  }

  Category _mapToEntity(db.Category row) {
    return Category(
      id: row.id,
      name: row.name,
      parentId: row.parentId,
      iconCodePoint: row.iconCodePoint,
      createdAt: row.createdAt,
      modifiedAt: row.modifiedAt,
    );
  }
}

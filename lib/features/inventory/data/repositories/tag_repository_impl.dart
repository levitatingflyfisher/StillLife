import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';

const _uuid = Uuid();

class TagRepositoryImpl implements TagRepository {
  final db.AppDatabase _db;

  TagRepositoryImpl(this._db);

  @override
  Stream<List<Tag>> watchTags() {
    return _db.tagDao.watchAllTags().map(
      (rows) => rows.map(_mapToEntity).toList(),
    );
  }

  @override
  Future<Result<Tag>> getTag(String id) async {
    try {
      final row = await _db.tagDao.getTagById(id);
      if (row == null) {
        return const Err(DatabaseFailure('Tag not found'));
      }
      return Success(_mapToEntity(row));
    } catch (e) {
      return Err(DatabaseFailure('Failed to get tag: $e'));
    }
  }

  @override
  Future<Result<Tag>> createTag(Tag tag) async {
    try {
      final now = DateTime.now();
      final id = tag.id.isEmpty ? _uuid.v4() : tag.id;
      final companion = db.TagsCompanion.insert(
        id: id,
        name: tag.name,
        color: Value(tag.color),
        createdAt: now,
        modifiedAt: now,
      );
      await _db.tagDao.insertTag(companion);
      return getTag(id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to create tag: $e'));
    }
  }

  @override
  Future<Result<Tag>> updateTag(Tag tag) async {
    try {
      final companion = db.TagsCompanion(
        id: Value(tag.id),
        name: Value(tag.name),
        color: Value(tag.color),
        modifiedAt: Value(DateTime.now()),
      );
      await _db.tagDao.updateTag(companion);
      return getTag(tag.id);
    } catch (e) {
      return Err(DatabaseFailure('Failed to update tag: $e'));
    }
  }

  @override
  Future<Result<void>> deleteTag(String id) async {
    try {
      await _db.tagDao.deleteTag(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete tag: $e'));
    }
  }

  @override
  Future<Result<void>> setItemTags(String itemId, List<String> tagIds) async {
    try {
      await _db.tagDao.setItemTags(itemId, tagIds);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to set item tags: $e'));
    }
  }

  @override
  Future<Result<List<Tag>>> getItemTags(String itemId) async {
    try {
      final rows = await _db.tagDao.getItemTags(itemId);
      return Success(rows.map(_mapToEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure('Failed to get item tags: $e'));
    }
  }

  Tag _mapToEntity(db.Tag row) {
    return Tag(
      id: row.id,
      name: row.name,
      color: row.color,
      createdAt: row.createdAt,
      modifiedAt: row.modifiedAt,
    );
  }
}

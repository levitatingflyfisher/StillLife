import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags, ItemTags, Items])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Stream<List<Tag>> watchAllTags() {
    return (select(tags)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<Tag?> getTagById(String id) {
    return (select(tags)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> insertTag(TagsCompanion entry, {CrdtManager? crdt}) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await into(tags).insert(entry);
  }

  Future<bool> updateTag(TagsCompanion entry, {CrdtManager? crdt}) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return (update(tags)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Soft-delete a tag. Junction rows in `itemTags` are hard-deleted (not
  /// individually synced — they are re-derived by setItemTags).
  ///
  /// When [crdt] is provided, stamps `nodeId`/`hlc` on the tombstone so the
  /// CRDT merge engine can propagate it to peers.
  Future<void> deleteTag(String id, {CrdtManager? crdt}) async {
    await (delete(itemTags)..where((t) => t.tagId.equals(id))).go();
    var entry = TagsCompanion(
      id: Value(id),
      isDeleted: const Value(true),
      modifiedAt: Value(DateTime.now()),
    );
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await (update(tags)..where((t) => t.id.equals(id))).write(entry);
  }

  /// Set the tags for an item (replaces all existing).
  Future<void> setItemTags(String itemId, List<String> tagIds) async {
    await (delete(itemTags)..where((t) => t.itemId.equals(itemId))).go();
    if (tagIds.isNotEmpty) {
      final now = DateTime.now();
      await batch((batch) {
        batch.insertAll(
          itemTags,
          tagIds
              .map(
                (tagId) => ItemTagsCompanion.insert(
                  itemId: itemId,
                  tagId: tagId,
                  createdAt: now,
                ),
              )
              .toList(),
        );
      });
    }
  }

  /// Get all tags for an item.
  Future<List<Tag>> getItemTags(String itemId) async {
    final query = select(tags).join([
      innerJoin(itemTags, itemTags.tagId.equalsExp(tags.id)),
    ])..where(itemTags.itemId.equals(itemId));
    final results = await query.get();
    return results.map((row) => row.readTable(tags)).toList();
  }

  /// Get tag IDs for an item.
  Future<List<String>> getItemTagIds(String itemId) async {
    final query = select(itemTags)..where((t) => t.itemId.equals(itemId));
    final results = await query.get();
    return results.map((r) => r.tagId).toList();
  }
}

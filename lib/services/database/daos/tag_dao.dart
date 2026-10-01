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

  /// Soft-delete a tag and tombstone its links.
  ///
  /// When [crdt] is provided, stamps `nodeId`/`hlc` on the tag tombstone and
  /// on each link tombstone so the merge propagates them. Links are
  /// tombstoned, never removed: a missing row would be refilled by any peer
  /// that still holds the live link.
  Future<void> deleteTag(String id, {CrdtManager? crdt}) async {
    final live = await (select(itemTags)
          ..where((t) => t.tagId.equals(id) & t.isDeleted.equals(false)))
        .get();
    for (final link in live) {
      await _writeLink(link.itemId, id, deleted: true, crdt: crdt);
    }
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

  /// Set the tags for an item. Only the pairs that change are written:
  /// removed links become stamped tombstones, added (or re-added) links are
  /// stamped live rows, and unchanged links keep their stamps. Each link
  /// then merges by last-writer-wins on its own.
  Future<void> setItemTags(
    String itemId,
    List<String> tagIds, {
    CrdtManager? crdt,
  }) async {
    await transaction(() async {
      final current = (await getItemTagIds(itemId)).toSet();
      final wanted = tagIds.toSet();
      for (final tagId in current.difference(wanted)) {
        await _writeLink(itemId, tagId, deleted: true, crdt: crdt);
      }
      for (final tagId in wanted.difference(current)) {
        await _writeLink(itemId, tagId, deleted: false, crdt: crdt);
      }
    });
  }

  /// Tombstones every live link of [itemId] (the item is being deleted at
  /// [deletedAt], the item tombstone's `modifiedAt`), marking each with that
  /// time so a later restore of the item revives exactly these links.
  Future<void> tombstoneLinksOfItem(
    String itemId, {
    required DateTime deletedAt,
    CrdtManager? crdt,
  }) async {
    for (final tagId in await getItemTagIds(itemId)) {
      await _writeLink(
        itemId,
        tagId,
        deleted: true,
        deletedWithItemAt: deletedAt,
        crdt: crdt,
      );
    }
  }

  /// Tag ids of [itemId]'s links tombstoned by the item's delete at
  /// [deletedAt] (see [tombstoneLinksOfItem]).
  Future<List<String>> tagIdsDeletedWithItem(
    String itemId,
    DateTime deletedAt,
  ) async {
    final rows = await (select(itemTags)..where(
          (t) =>
              t.itemId.equals(itemId) &
              t.isDeleted.equals(true) &
              t.deletedWithItemAt.equals(deletedAt),
        ))
        .get();
    return [for (final r in rows) r.tagId];
  }

  /// Upserts one (item, tag) link as live or tombstoned, stamped when [crdt]
  /// is given.
  Future<void> _writeLink(
    String itemId,
    String tagId, {
    required bool deleted,
    DateTime? deletedWithItemAt,
    CrdtManager? crdt,
  }) async {
    var row = ItemTagsCompanion.insert(
      itemId: itemId,
      tagId: tagId,
      createdAt: DateTime.now(),
      isDeleted: Value(deleted),
      deletedWithItemAt: Value(deletedWithItemAt),
    );
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      row = row.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await into(itemTags).insert(
      row,
      onConflict: DoUpdate(
        (_) => ItemTagsCompanion(
          isDeleted: row.isDeleted,
          deletedWithItemAt: row.deletedWithItemAt,
          nodeId: row.nodeId,
          hlc: row.hlc,
        ),
      ),
    );
  }

  /// Get all tags for an item.
  Future<List<Tag>> getItemTags(String itemId) async {
    final query = select(tags).join([
      innerJoin(itemTags, itemTags.tagId.equalsExp(tags.id)),
    ])..where(itemTags.itemId.equals(itemId) &
          itemTags.isDeleted.equals(false) &
          tags.isDeleted.equals(false));
    final results = await query.get();
    return results.map((row) => row.readTable(tags)).toList();
  }

  /// Get tag IDs for an item.
  Future<List<String>> getItemTagIds(String itemId) async {
    final query = select(itemTags)
      ..where((t) => t.itemId.equals(itemId) & t.isDeleted.equals(false));
    final results = await query.get();
    return results.map((r) => r.tagId).toList();
  }
}

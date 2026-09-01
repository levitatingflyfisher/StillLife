import 'package:flutter/foundation.dart' show debugPrint;
import 'package:drift/drift.dart';

import '../../../services/database/database.dart';
import '../../../services/sync/crdt_manager.dart';

/// A deleted item as Recently deleted lists it.
class DeletedItem {
  final String id;
  final String name;
  final DateTime deletedAt;

  const DeletedItem({
    required this.id,
    required this.name,
    required this.deletedAt,
  });
}

/// What an Undo needs that the tombstone alone does not keep: the item's
/// tag links, which the delete removes outright (they are not synced).
class ItemDeletion {
  final List<String> itemIds;
  final Map<String, List<String>> tagIdsByItem;

  const ItemDeletion(this.itemIds, this.tagIdsByItem);
}

/// The way back from a delete.
///
/// Every delete in Still Life is soft: the row stays as a sync tombstone
/// (`isDeleted`), so the reversal already exists in storage. This flips it
/// back. A restore bumps `modifiedAt` and, when a [CrdtManager] is given,
/// stamps a fresh HLC, so the restore wins last-writer-wins against the
/// tombstone on the next sync instead of losing to it.
///
/// There is deliberately no "delete forever": hard-deleting a synced
/// tombstone would let a peer that still holds the live row send it back.
class RecentlyDeletedRepository {
  final AppDatabase _db;
  final CrdtManager? _crdt;

  RecentlyDeletedRepository(this._db, {CrdtManager? crdt}) : _crdt = crdt;

  Future<({String nodeId, String hlc})?> _stamp() async {
    final crdt = _crdt;
    if (crdt == null) return null;
    // Same rule as SyncStamp: a keystore hiccup must not block a restore;
    // the row is then restored unstamped.
    try {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      return (nodeId: nodeId, hlc: hlc.toString());
    } catch (e) {
      debugPrint('Still Life: sync clock unavailable, restore unstamped: $e');
      return null;
    }
  }

  /// The clock for a DAO write, or null (unstamped) when the keystore is
  /// unavailable: same rule as [_stamp].
  Future<CrdtManager?> _clock() async {
    final crdt = _crdt;
    if (crdt == null) return null;
    try {
      await crdt.getNodeId();
      return crdt;
    } catch (e) {
      debugPrint('Still Life: sync clock unavailable, restore unstamped: $e');
      return null;
    }
  }

  /// Call before deleting [itemIds]: captures what the delete drops.
  Future<ItemDeletion> snapshot(List<String> itemIds) async {
    final tags = <String, List<String>>{};
    for (final id in itemIds) {
      tags[id] = await _db.tagDao.getItemTagIds(id);
    }
    return ItemDeletion(List.unmodifiable(itemIds), tags);
  }

  /// Undo for a delete captured by [snapshot].
  Future<void> restoreItems(ItemDeletion deletion) async {
    for (final id in deletion.itemIds) {
      await restoreItem(id, tagIds: deletion.tagIdsByItem[id]);
    }
  }

  /// Restores one item and the photos that were deleted with it. A photo
  /// deleted on its own earlier has a different `modifiedAt` and stays
  /// deleted.
  Future<void> restoreItem(String id, {List<String>? tagIds}) async {
    final row = await (_db.select(
      _db.items,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null || !row.isDeleted) return;
    final deletedAt = row.modifiedAt;
    final now = DateTime.now();
    await _db.transaction(() async {
      final photos =
          await (_db.select(_db.photos)..where(
                (t) =>
                    t.itemId.equals(id) &
                    t.isDeleted.equals(true) &
                    t.modifiedAt.equals(deletedAt),
              ))
              .get();
      for (final photo in photos) {
        final stamp = await _stamp();
        await (_db.update(
          _db.photos,
        )..where((t) => t.id.equals(photo.id))).write(
          PhotosCompanion(
            isDeleted: const Value(false),
            modifiedAt: Value(now),
            nodeId: stamp == null ? const Value.absent() : Value(stamp.nodeId),
            hlc: stamp == null ? const Value.absent() : Value(stamp.hlc),
          ),
        );
      }
      final stamp = await _stamp();
      await (_db.update(_db.items)..where((t) => t.id.equals(id))).write(
        ItemsCompanion(
          isDeleted: const Value(false),
          modifiedAt: Value(now),
          nodeId: stamp == null ? const Value.absent() : Value(stamp.nodeId),
          hlc: stamp == null ? const Value.absent() : Value(stamp.hlc),
        ),
      );
      if (tagIds != null && tagIds.isNotEmpty) {
        await _db.tagDao.setItemTags(id, tagIds, crdt: await _clock());
      }
    });
  }

  /// Deleted items, most recently deleted first.
  Stream<List<DeletedItem>> watchDeletedItems() {
    final query = _db.select(_db.items)
      ..where((t) => t.isDeleted.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          DeletedItem(id: r.id, name: r.name, deletedAt: r.modifiedAt),
      ],
    );
  }

  Future<void> restoreRoom(String id) async {
    final stamp = await _stamp();
    await (_db.update(_db.rooms)..where((t) => t.id.equals(id))).write(
      RoomsCompanion(
        isDeleted: const Value(false),
        modifiedAt: Value(DateTime.now()),
        nodeId: stamp == null ? const Value.absent() : Value(stamp.nodeId),
        hlc: stamp == null ? const Value.absent() : Value(stamp.hlc),
      ),
    );
  }

  Future<void> restorePolicy(String id) async {
    final stamp = await _stamp();
    await (_db.update(_db.policies)..where((t) => t.id.equals(id))).write(
      PoliciesCompanion(
        isDeleted: const Value(false),
        modifiedAt: Value(DateTime.now()),
        nodeId: stamp == null ? const Value.absent() : Value(stamp.nodeId),
        hlc: stamp == null ? const Value.absent() : Value(stamp.hlc),
      ),
    );
  }

  Future<void> restoreMaintenanceLog(String id) async {
    final stamp = await _stamp();
    await (_db.update(
      _db.maintenanceLogs,
    )..where((t) => t.id.equals(id))).write(
      MaintenanceLogsCompanion(
        isDeleted: const Value(false),
        modifiedAt: Value(DateTime.now()),
        nodeId: stamp == null ? const Value.absent() : Value(stamp.nodeId),
        hlc: stamp == null ? const Value.absent() : Value(stamp.hlc),
      ),
    );
  }

  Future<void> restoreCategory(String id) async {
    final stamp = await _stamp();
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        isDeleted: const Value(false),
        modifiedAt: Value(DateTime.now()),
        nodeId: stamp == null ? const Value.absent() : Value(stamp.nodeId),
        hlc: stamp == null ? const Value.absent() : Value(stamp.hlc),
      ),
    );
  }

  /// Items carrying [tagId]; call before deleting the tag, whose links the
  /// delete removes.
  Future<List<String>> itemsTagged(String tagId) async {
    final rows = await (_db.select(_db.itemTags)
          ..where((t) => t.tagId.equals(tagId) & t.isDeleted.equals(false)))
        .get();
    return [for (final r in rows) r.itemId];
  }

  Future<void> restoreTag(String id, {List<String> itemIds = const []}) async {
    final stamp = await _stamp();
    await _db.transaction(() async {
      await (_db.update(_db.tags)..where((t) => t.id.equals(id))).write(
        TagsCompanion(
          isDeleted: const Value(false),
          modifiedAt: Value(DateTime.now()),
          nodeId: stamp == null ? const Value.absent() : Value(stamp.nodeId),
          hlc: stamp == null ? const Value.absent() : Value(stamp.hlc),
        ),
      );
      final crdt = await _clock();
      for (final itemId in itemIds) {
        final current = await _db.tagDao.getItemTagIds(itemId);
        await _db.tagDao.setItemTags(itemId, [...current, id], crdt: crdt);
      }
    });
  }
}

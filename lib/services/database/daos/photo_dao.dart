import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'photo_dao.g.dart';

@DriftAccessor(tables: [Photos])
class PhotoDao extends DatabaseAccessor<AppDatabase> with _$PhotoDaoMixin {
  PhotoDao(super.db);

  Stream<List<Photo>> watchItemPhotos(String itemId) {
    return (select(photos)
          ..where((t) => t.itemId.equals(itemId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPrimary),
            (t) => OrderingTerm.asc(t.capturedAt),
          ]))
        .watch();
  }

  Future<Photo?> getPhotoById(String id) {
    return (select(photos)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<Photo?> getPrimaryPhoto(String itemId) {
    return (select(photos)
          ..where(
            (t) =>
                t.itemId.equals(itemId) &
                t.isPrimary.equals(true) &
                t.isDeleted.equals(false),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  /// Returns the file paths of all photos for [itemId] (used before deletion).
  Future<List<String>> getPhotoFilePathsForItem(String itemId) async {
    final rows = await (select(
      photos,
    )..where((t) => t.itemId.equals(itemId))).get();
    return rows.map((r) => r.filePath).toList();
  }

  Future<void> insertPhoto(PhotosCompanion entry, {CrdtManager? crdt}) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await into(photos).insert(entry);
  }

  /// Soft-deletes one photo. It was a hard delete, which left peers nothing
  /// to merge: a device that still had the row would send it straight back.
  /// A tombstone stamped through [crdt] propagates like any other edit.
  /// The image bytes are dropped: a photo the household deleted on purpose
  /// should not linger in the database, and a tombstone needs no picture.
  Future<void> deletePhoto(String id, {CrdtManager? crdt}) async {
    var entry = PhotosCompanion(
      isDeleted: const Value(true),
      bytes: const Value(null),
      thumbBytes: const Value(null),
      modifiedAt: Value(DateTime.now()),
    );
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await (update(photos)..where((t) => t.id.equals(id))).write(entry);
  }

  /// Makes [photoId] the item's primary photo. Every photo whose flag
  /// changes gets its own stamp when [crdt] is given, so the choice syncs
  /// instead of losing to a peer's older copy.
  Future<void> setPrimaryPhoto(
    String itemId,
    String photoId, {
    CrdtManager? crdt,
  }) async {
    final now = DateTime.now();
    final rows = await (select(
      photos,
    )..where((t) => t.itemId.equals(itemId))).get();
    for (final row in rows) {
      final want = row.id == photoId;
      if (row.isPrimary == want) continue;
      var entry = PhotosCompanion(
        isPrimary: Value(want),
        modifiedAt: Value(now),
      );
      if (crdt != null) {
        final nodeId = await crdt.getNodeId();
        final hlc = await crdt.nextHlc();
        entry = entry.copyWith(
          nodeId: Value(nodeId),
          hlc: Value(hlc.toString()),
        );
      }
      await (update(photos)..where((t) => t.id.equals(row.id))).write(entry);
    }
  }

  Future<List<Photo>> getItemPhotos(String itemId) {
    return (select(photos)
          ..where((t) => t.itemId.equals(itemId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPrimary),
            (t) => OrderingTerm.asc(t.capturedAt),
          ]))
        .get();
  }
}

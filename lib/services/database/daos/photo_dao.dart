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

  Future<void> deletePhoto(String id) {
    return (delete(photos)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setPrimaryPhoto(String itemId, String photoId) async {
    // Clear existing primary
    await (update(photos)..where((t) => t.itemId.equals(itemId))).write(
      const PhotosCompanion(isPrimary: Value(false)),
    );
    // Set new primary
    await (update(photos)..where((t) => t.id.equals(photoId))).write(
      PhotosCompanion(
        isPrimary: const Value(true),
        modifiedAt: Value(DateTime.now()),
      ),
    );
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

import 'package:drift/drift.dart';

import 'package:still_life/services/database/database.dart';

/// Session bookkeeping for video walkthroughs — the first real writer of
/// the `VideoAnalyses` table. One row per run: `processing` while the
/// pipeline works, then `completed` / `failed` / `no_ai` / `cancelled`
/// (user stopped the run) with honest frame and item counts.
class VideoSessionLog {
  final AppDatabase _db;

  VideoSessionLog(this._db);

  Future<void> begin({
    required String id,
    required String videoPath,
    String? roomId,
    String? providerTier,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.videoAnalyses).insertOnConflictUpdate(
      VideoAnalysesCompanion.insert(
        id: id,
        videoPath: videoPath,
        roomId: Value(roomId),
        status: 'processing',
        providerTier: Value(providerTier),
        startedAt: Value(now),
        createdAt: now,
        modifiedAt: now,
      ),
    );
  }

  Future<void> finish({
    required String id,
    required String status,
    required int frameCount,
    required int itemsDetected,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.videoAnalyses)..where((t) => t.id.equals(id))).write(
      VideoAnalysesCompanion(
        status: Value(status),
        frameCount: Value(frameCount),
        itemsDetected: Value(itemsDetected),
        completedAt: Value(now),
        modifiedAt: Value(now),
      ),
    );
  }

  /// The run that never started: no AI tier is configured. One complete
  /// row, so the history stays honest about attempts too.
  Future<void> recordNoAi({
    required String id,
    required String videoPath,
    String? roomId,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.videoAnalyses).insertOnConflictUpdate(
      VideoAnalysesCompanion.insert(
        id: id,
        videoPath: videoPath,
        roomId: Value(roomId),
        status: 'no_ai',
        startedAt: Value(now),
        completedAt: Value(now),
        createdAt: now,
        modifiedAt: now,
      ),
    );
  }
}

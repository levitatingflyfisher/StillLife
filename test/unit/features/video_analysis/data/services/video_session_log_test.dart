import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/data/services/video_session_log.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late VideoSessionLog log;

  setUp(() {
    db = AppDatabase.memory();
    log = VideoSessionLog(db);
  });

  tearDown(() => db.close());

  test('begin writes a processing row with tier and start time', () async {
    await log.begin(
      id: 'vs-1',
      videoPath: '/tmp/walk.mp4',
      roomId: 'room-1',
      providerTier: 'localLlm',
    );

    final row = await db.select(db.videoAnalyses).getSingle();
    expect(row.id, 'vs-1');
    expect(row.videoPath, '/tmp/walk.mp4');
    expect(row.roomId, 'room-1');
    expect(row.status, 'processing');
    expect(row.providerTier, 'localLlm');
    expect(row.startedAt, isNotNull);
    expect(row.completedAt, isNull);
  });

  test('finish updates the same row with counts and completion', () async {
    await log.begin(id: 'vs-1', videoPath: '/tmp/walk.mp4');
    await log.finish(
      id: 'vs-1',
      status: 'completed',
      frameCount: 34,
      itemsDetected: 7,
    );

    final row = await db.select(db.videoAnalyses).getSingle();
    expect(row.status, 'completed');
    expect(row.frameCount, 34);
    expect(row.itemsDetected, 7);
    expect(row.completedAt, isNotNull);
  });

  test('recordNoAi writes a complete no_ai row in one shot', () async {
    await log.recordNoAi(id: 'vs-2', videoPath: '/tmp/walk.mp4');

    final row = await db.select(db.videoAnalyses).getSingle();
    expect(row.status, 'no_ai');
    expect(row.providerTier, isNull);
    expect(row.frameCount, 0);
    expect(row.itemsDetected, 0);
    expect(row.completedAt, isNotNull);
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/data/services/analysis_orchestrator.dart';
import 'package:still_life/features/video_analysis/data/services/frame_extraction_exception.dart';
import 'package:still_life/features/video_analysis/data/services/video_session_log.dart';
import 'package:still_life/features/video_analysis/domain/entities/analysis_session.dart';
import 'package:still_life/features/video_analysis/domain/entities/frame_data.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/provider_manager.dart';

import '../../../../../test_setup.dart';

/// Frame whose first image byte encodes its index, so the fake provider
/// can answer per-frame.
FrameData _frame(int index, {double sharpness = 500.0, String? hash}) =>
    FrameData(
      index: index,
      timestamp: index / 2.0,
      imageBytes: Uint8List.fromList([index, 7, 7]),
      width: 8,
      height: 8,
      sharpness: sharpness,
      perceptualHash: hash ?? (index * 1111).toRadixString(16).padLeft(16, '0'),
    );

AnalysisResult _result(String name, {double confidence = 0.8}) =>
    AnalysisResult(
      itemName: name,
      description: '',
      category: 'Other',
      confidence: confidence,
    );

/// A VLM stand-in: available, answers analyzeImageMulti per frame index.
class _FakeVlmProvider extends AnalysisProvider {
  final Map<int, List<AnalysisResult>> answers;
  final Set<int> throwOn;
  final bool available;

  _FakeVlmProvider({
    this.answers = const {},
    this.throwOn = const {},
    this.available = true,
  });

  @override
  String get name => 'Fake VLM';

  @override
  AnalysisTier get tier => AnalysisTier.localLlm;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<AnalysisResult>> analyzeImageMulti(
    Uint8List imageBytes, {
    AnalysisContext? context,
  }) async {
    final frameIndex = imageBytes.first;
    if (throwOn.contains(frameIndex)) {
      throw Exception('frame $frameIndex refused');
    }
    return answers[frameIndex] ?? const [];
  }

  @override
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  }) => throw UnimplementedError();

  @override
  Future<AnalysisResult> analyzeText(
    String prompt, {
    AnalysisContext? context,
  }) => throw UnimplementedError();

  @override
  Future<String> completeText(String prompt, {int maxTokens = 1000}) =>
      throw UnimplementedError();
}

void main() {
  ensureSqlite3();

  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  AnalysisOrchestrator orchestrator({
    required List<FrameData> frames,
    required AnalysisProvider provider,
    Object? extractionError,
  }) => AnalysisOrchestrator(
    frames: ({required String videoPath, required AnalysisConfig config}) async* {
      for (final f in frames) {
        yield f;
      }
      if (extractionError != null) throw extractionError;
    },
    providerManager: ProviderManager(providers: [provider]),
    sessionLog: VideoSessionLog(db),
  );

  test('no available tier yields VideoNoAiConfigured and a no_ai row',
      () async {
    final events = await orchestrator(
      frames: [_frame(0)],
      provider: _FakeVlmProvider(available: false),
    ).analyze(
      sessionId: 'vs-1',
      videoPath: '/tmp/walk.mp4',
      config: const AnalysisConfig(),
    ).toList();

    expect(events, hasLength(1));
    expect(events.single, isA<VideoNoAiConfigured>());

    final row = await db.select(db.videoAnalyses).getSingle();
    expect(row.status, 'no_ai');
  });

  test('analyzes selected frames, merges across them, records the session',
      () async {
    final provider = _FakeVlmProvider(answers: {
      0: [_result('Sony TV', confidence: 0.6)],
      1: [_result('sony tv', confidence: 0.9), _result('Floor lamp')],
      2: [],
    });

    final events = await orchestrator(
      frames: [_frame(0), _frame(1), _frame(2)],
      provider: provider,
    ).analyze(
      sessionId: 'vs-2',
      videoPath: '/tmp/walk.mp4',
      roomId: 'room-1',
      config: const AnalysisConfig(),
    ).toList();

    expect(
      events.whereType<VideoAnalysisStarted>().single.tier,
      AnalysisTier.localLlm,
    );
    expect(
      events.whereType<VideoStageChanged>().map((e) => e.stage).toList(),
      [
        AnalysisStatus.extracting,
        AnalysisStatus.selecting,
        AnalysisStatus.analyzing,
      ],
    );
    expect(events.whereType<VideoFramesSelected>().single.count, 3);

    final completed = events.whereType<VideoAnalysisCompleted>().single;
    expect(completed.items, hasLength(2));

    final tv = completed.items.firstWhere(
      (i) => i.label.toLowerCase() == 'sony tv',
    );
    // The winning copy came from frame 1 — so does its source image.
    expect(tv.confidence, 0.9);
    expect(tv.frameIndex, 1);
    expect(tv.frameImage, Uint8List.fromList([1, 7, 7]));

    final row = await db.select(db.videoAnalyses).getSingle();
    expect(row.status, 'completed');
    expect(row.providerTier, 'localLlm');
    expect(row.frameCount, 3);
    expect(row.itemsDetected, 2);
    expect(row.roomId, 'room-1');
  });

  test('a frame that throws is skipped; the rest still land', () async {
    final provider = _FakeVlmProvider(
      answers: {
        0: [_result('Couch')],
        2: [_result('Piano')],
      },
      throwOn: {1},
    );

    final events = await orchestrator(
      frames: [_frame(0), _frame(1), _frame(2)],
      provider: provider,
    ).analyze(
      sessionId: 'vs-3',
      videoPath: '/tmp/walk.mp4',
      config: const AnalysisConfig(),
    ).toList();

    final completed = events.whereType<VideoAnalysisCompleted>().single;
    expect(
      completed.items.map((i) => i.label).toList()..sort(),
      ['Couch', 'Piano'],
    );
  });

  test('extraction failure yields VideoAnalysisFailed and a failed row',
      () async {
    final events = await orchestrator(
      frames: [_frame(0)],
      provider: _FakeVlmProvider(),
      extractionError: const FrameExtractionException('ffmpeg rc 1'),
    ).analyze(
      sessionId: 'vs-4',
      videoPath: '/tmp/walk.mp4',
      config: const AnalysisConfig(),
    ).toList();

    expect(
      events.whereType<VideoAnalysisFailed>().single.message,
      contains('ffmpeg rc 1'),
    );
    expect(events.whereType<VideoAnalysisCompleted>(), isEmpty);

    final row = await db.select(db.videoAnalyses).getSingle();
    expect(row.status, 'failed');
  });

  test('caps merged items at maxObjectsPerSession', () async {
    final provider = _FakeVlmProvider(answers: {
      0: [_result('A'), _result('B'), _result('C'), _result('D')],
    });

    final events = await orchestrator(
      frames: [_frame(0)],
      provider: provider,
    ).analyze(
      sessionId: 'vs-5',
      videoPath: '/tmp/walk.mp4',
      config: const AnalysisConfig(maxObjectsPerSession: 2),
    ).toList();

    final completed = events.whereType<VideoAnalysisCompleted>().single;
    expect(completed.items, hasLength(2));

    final row = await db.select(db.videoAnalyses).getSingle();
    expect(row.itemsDetected, 2);
  });

  test('progress events count analysis calls over selected frames', () async {
    final provider = _FakeVlmProvider(answers: {
      0: [_result('Couch')],
      1: [_result('couch', confidence: 0.9)],
    });

    final events = await orchestrator(
      frames: [_frame(0), _frame(1)],
      provider: provider,
    ).analyze(
      sessionId: 'vs-6',
      videoPath: '/tmp/walk.mp4',
      config: const AnalysisConfig(),
    ).toList();

    final analyzeTicks = events
        .whereType<VideoFrameProgress>()
        .where((e) => e.total == 2)
        .toList();
    expect(analyzeTicks.map((e) => e.processed).toList(), [1, 2]);
    // The running item count is the MERGED count — the same couch seen in
    // both frames stays one item.
    expect(analyzeTicks.last.itemsSoFar, 1);
  });

  test('mid-analysis progress events carry the merged partial items — '
      'Stop & Review must have something to keep', () async {
    final events = await orchestrator(
      frames: [_frame(0), _frame(1)],
      provider: _FakeVlmProvider(
        answers: {
          0: [_result('Couch')],
          1: [_result('Lamp')],
        },
      ),
    ).analyze(
      sessionId: 'vs-partial',
      videoPath: '/tmp/walk.mp4',
      config: const AnalysisConfig(),
    ).toList();

    final analysisProgress = events
        .whereType<VideoFrameProgress>()
        .where((e) => e.total > 0)
        .toList();
    expect(analysisProgress, isNotEmpty);
    expect(analysisProgress.first.items, isNotEmpty,
        reason: 'the first analyzed frame already produced a reviewable '
            'item; cancelling here must not discard it');
    expect(
      analysisProgress.last.items.map((o) => o.label),
      containsAll(['Couch', 'Lamp']),
    );
  });
}

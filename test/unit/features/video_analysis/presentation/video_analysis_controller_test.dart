import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/data/services/analysis_orchestrator.dart';
import 'package:still_life/features/video_analysis/data/services/frame_extraction_exception.dart';
import 'package:still_life/features/video_analysis/domain/entities/analysis_session.dart';
import 'package:still_life/features/video_analysis/domain/entities/frame_data.dart';
import 'package:still_life/features/video_analysis/presentation/controllers/video_analysis_controller.dart';
import 'package:still_life/features/video_analysis/data/services/video_session_log.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/provider_manager.dart';

import '../../../../test_setup.dart';

FrameData _frame(int index) => FrameData(
  index: index,
  timestamp: index / 2.0,
  imageBytes: Uint8List.fromList([index]),
  width: 8,
  height: 8,
  sharpness: 500.0,
  perceptualHash: (index * 1111).toRadixString(16).padLeft(16, '0'),
);

class _FakeVlmProvider extends AnalysisProvider {
  final bool available;

  _FakeVlmProvider({this.available = true});

  @override
  String get name => 'Fake VLM';

  @override
  AnalysisTier get tier => AnalysisTier.cloudApi;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<AnalysisResult>> analyzeImageMulti(
    Uint8List imageBytes, {
    AnalysisContext? context,
  }) async => const [
    AnalysisResult(
      itemName: 'Couch',
      description: '',
      category: 'Furniture',
      confidence: 0.9,
    ),
  ];

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

/// Like [_FakeVlmProvider] but each analyzeImageMulti call after the
/// first waits on [gate] — freezing the pipeline mid-analysis so tests
/// can cancel/stop at a deterministic point.
class _GatedVlmProvider extends _FakeVlmProvider {
  final Completer<void> gate;
  int calls = 0;

  _GatedVlmProvider(this.gate);

  @override
  Future<List<AnalysisResult>> analyzeImageMulti(
    Uint8List imageBytes, {
    AnalysisContext? context,
  }) async {
    calls++;
    if (calls > 1) await gate.future;
    return super.analyzeImageMulti(imageBytes, context: context);
  }
}

ProviderContainer _container({
  required List<FrameData> frames,
  required AnalysisProvider provider,
  Object? extractionError,
  VideoSessionLog? sessionLog,
}) {
  final orchestrator = AnalysisOrchestrator(
    frames:
        ({required String videoPath, required AnalysisConfig config}) async* {
          for (final f in frames) {
            yield f;
          }
          if (extractionError != null) throw extractionError;
        },
    providerManager: ProviderManager(providers: [provider]),
    sessionLog: sessionLog,
  );
  return ProviderContainer(
    overrides: [
      analysisOrchestratorProvider.overrideWithValue(orchestrator),
      if (sessionLog != null)
        videoSessionLogProvider.overrideWithValue(sessionLog),
    ],
  );
}

/// Distinct-hash frames so the quality gate keeps both.
FrameData _distinctFrame(int index) => FrameData(
  index: index,
  timestamp: index / 2.0,
  imageBytes: Uint8List.fromList([index]),
  width: 8,
  height: 8,
  sharpness: 500.0,
  perceptualHash: index == 0
      ? '0000000000000000'
      : 'ffffffffffffffff',
);

void main() {
  test('runAnalysis drives the session to review with merged items',
      () async {
    final container = _container(
      frames: [_frame(0), _frame(1)],
      provider: _FakeVlmProvider(),
    );
    addTearDown(container.dispose);

    final controller =
        container.read(videoAnalysisControllerProvider.notifier);
    await controller.runAnalysis(videoPath: '/tmp/walk.mp4', roomId: 'r-1');

    final session = container.read(videoAnalysisControllerProvider)!;
    expect(session.status, AnalysisStatus.reviewing);
    expect(session.providerTier, AnalysisTier.cloudApi);
    expect(session.selectedFrames, 2);
    expect(session.itemsSoFar, 1); // the same couch in both frames, merged
    expect(session.detectedObjects, hasLength(1));
    expect(session.detectedObjects.single.label, 'Couch');
    expect(session.roomId, 'r-1');
  });

  test('no AI tier lands in the honest noAiConfigured state', () async {
    final container = _container(
      frames: [_frame(0)],
      provider: _FakeVlmProvider(available: false),
    );
    addTearDown(container.dispose);

    final controller =
        container.read(videoAnalysisControllerProvider.notifier);
    await controller.runAnalysis(videoPath: '/tmp/walk.mp4');

    final session = container.read(videoAnalysisControllerProvider)!;
    expect(session.status, AnalysisStatus.noAiConfigured);
    expect(session.isProcessing, false);
  });

  test('extraction failure lands in failed with the message', () async {
    final container = _container(
      frames: [],
      provider: _FakeVlmProvider(),
      extractionError: const FrameExtractionException('ffmpeg rc 1'),
    );
    addTearDown(container.dispose);

    final controller =
        container.read(videoAnalysisControllerProvider.notifier);
    await controller.runAnalysis(videoPath: '/tmp/walk.mp4');

    final session = container.read(videoAnalysisControllerProvider)!;
    expect(session.status, AnalysisStatus.failed);
    expect(session.failureMessage, contains('ffmpeg rc 1'));
  });

  test('the session exists before the first await', () async {
    final container = _container(
      frames: [_frame(0)],
      provider: _FakeVlmProvider(),
    );
    addTearDown(container.dispose);

    final controller =
        container.read(videoAnalysisControllerProvider.notifier);
    final run = controller.runAnalysis(videoPath: '/tmp/walk.mp4');

    // Before any await completes the session must already exist —
    // navigation to the processing screen happens immediately.
    expect(container.read(videoAnalysisControllerProvider), isNotNull);

    await run;
  });

  group('mid-run cancellation contract', () {
    late AppDatabase db;

    setUp(() {
      ensureSqlite3();
      db = AppDatabase.memory();
    });

    tearDown(() => db.close());

    Future<void> pumpUntil(
      ProviderContainer container,
      bool Function(AnalysisSession?) predicate,
    ) async {
      for (var i = 0; i < 200; i++) {
        await Future<void>.delayed(Duration.zero);
        if (predicate(container.read(videoAnalysisControllerProvider))) {
          return;
        }
      }
      fail('condition never reached');
    }

    test('cancelAnalysis stops the pipeline and marks the session row '
        'cancelled — never an eternal processing row', () async {
      final gate = Completer<void>();
      final log = VideoSessionLog(db);
      final container = _container(
        frames: [_distinctFrame(0), _distinctFrame(1)],
        provider: _GatedVlmProvider(gate),
        sessionLog: log,
      );
      addTearDown(container.dispose);

      final controller =
          container.read(videoAnalysisControllerProvider.notifier);
      final run = controller.runAnalysis(videoPath: '/tmp/walk.mp4');
      await pumpUntil(container, (s) => (s?.itemsSoFar ?? 0) > 0);

      await controller.cancelAnalysis();
      expect(container.read(videoAnalysisControllerProvider), isNull);

      gate.complete();
      await run;

      final row = await db.select(db.videoAnalyses).getSingle();
      expect(row.status, 'cancelled',
          reason: 'reset() used to strand the row at processing forever — '
              'the orchestrator generator dies mid-yield and its own '
              'finish() never runs');
      expect(row.completedAt, isNotNull);
    });

    test('stopAndReview keeps the partial findings and still closes the '
        'session row', () async {
      final gate = Completer<void>();
      final log = VideoSessionLog(db);
      final container = _container(
        frames: [_distinctFrame(0), _distinctFrame(1)],
        provider: _GatedVlmProvider(gate),
        sessionLog: log,
      );
      addTearDown(container.dispose);

      final controller =
          container.read(videoAnalysisControllerProvider.notifier);
      final run = controller.runAnalysis(videoPath: '/tmp/walk.mp4');
      await pumpUntil(
        container,
        (s) => (s?.detectedObjects.isNotEmpty ?? false),
      );

      await controller.stopAndReview();

      final session = container.read(videoAnalysisControllerProvider)!;
      expect(session.status, AnalysisStatus.reviewing);
      expect(session.detectedObjects, isNotEmpty,
          reason: 'the paid-for partial findings must be reviewable');

      gate.complete();
      await run;

      final row = await db.select(db.videoAnalyses).getSingle();
      expect(row.status, 'cancelled');
      expect(
        container.read(videoAnalysisControllerProvider)!.status,
        AnalysisStatus.reviewing,
        reason: 'late pipeline events must not clobber the stopped state',
      );
    });
  });
}

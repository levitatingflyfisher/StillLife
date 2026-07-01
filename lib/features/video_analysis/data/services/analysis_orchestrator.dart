import 'dart:typed_data';

import 'package:still_life/features/video_analysis/domain/entities/analysis_session.dart';
import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';
import 'package:still_life/features/video_analysis/domain/entities/frame_data.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/provider_manager.dart';

import 'frame_quality_gate.dart';
import 'suggestion_merger.dart';
import 'video_session_log.dart';

/// The extraction seam: native builds plug in the ffmpeg extractor, tests
/// plug in a canned stream, web gets the honest unsupported error.
typedef FrameStream =
    Stream<FrameData> Function({
      required String videoPath,
      required AnalysisConfig config,
    });

/// What the orchestrator tells the UI, one event at a time.
sealed class VideoAnalysisEvent {
  const VideoAnalysisEvent();
}

/// A tier was found; the pipeline is running on it.
final class VideoAnalysisStarted extends VideoAnalysisEvent {
  final AnalysisTier tier;
  const VideoAnalysisStarted(this.tier);
}

/// No AI tier is configured/available. Not an error — the UI explains and
/// points at Settings instead of spinning.
final class VideoNoAiConfigured extends VideoAnalysisEvent {
  const VideoNoAiConfigured();
}

/// The pipeline moved to a new stage.
final class VideoStageChanged extends VideoAnalysisEvent {
  final AnalysisStatus stage;
  const VideoStageChanged(this.stage);
}

/// Work ticked forward. During extraction [total] is 0 (ffmpeg does not
/// announce frame counts up front); during analysis it is the selected
/// frame count. [itemsSoFar] is always the MERGED item count and
/// [items] the merged partial findings so far — so stopping mid-run has
/// something reviewable to keep (empty during extraction).
final class VideoFrameProgress extends VideoAnalysisEvent {
  final int processed;
  final int total;
  final int itemsSoFar;
  final List<DetectedObject> items;
  const VideoFrameProgress({
    required this.processed,
    required this.total,
    required this.itemsSoFar,
    this.items = const [],
  });
}

/// The quality gate chose the frames — each one costs one analysis call,
/// so this is the moment the cost disclosure becomes concrete.
final class VideoFramesSelected extends VideoAnalysisEvent {
  final int count;
  const VideoFramesSelected(this.count);
}

/// The walkthrough is analyzed; [items] are merged and review-ready.
final class VideoAnalysisCompleted extends VideoAnalysisEvent {
  final List<DetectedObject> items;
  const VideoAnalysisCompleted(this.items);
}

/// The pipeline could not finish (extraction failure, etc.).
final class VideoAnalysisFailed extends VideoAnalysisEvent {
  final String message;
  const VideoAnalysisFailed(this.message);
}

/// Coordinates the VLM walkthrough pipeline:
///
/// 1. **Extract** frames at [AnalysisConfig.framesPerSecond] (ffmpeg seam)
/// 2. **Select** the frames worth paying for ([FrameQualityGate])
/// 3. **Analyze** each selected frame with `analyzeImageMulti` on the best
///    available tier — the same guarded multi-item path shelf photos use
/// 4. **Merge** findings across frames ([SuggestionMerger]) so one couch
///    seen in twelve frames is one review row, tagged with its source frame
///
/// Every run is recorded in the `VideoAnalyses` table via
/// [VideoSessionLog]. A single frame failing analysis is skipped; only
/// extraction failure sinks the run.
class AnalysisOrchestrator {
  final FrameStream _frames;
  final ProviderManager _providerManager;
  final FrameQualityGate _gate;
  final SuggestionMerger _merger;
  final VideoSessionLog? _sessionLog;

  AnalysisOrchestrator({
    required FrameStream frames,
    required ProviderManager providerManager,
    FrameQualityGate gate = const FrameQualityGate(),
    SuggestionMerger merger = const SuggestionMerger(),
    VideoSessionLog? sessionLog,
  }) : _frames = frames,
       _providerManager = providerManager,
       _gate = gate,
       _merger = merger,
       _sessionLog = sessionLog;

  Stream<VideoAnalysisEvent> analyze({
    required String sessionId,
    required String videoPath,
    required AnalysisConfig config,
    String? roomId,
  }) async* {
    AnalysisProvider? provider;
    try {
      // Every walkthrough frame is a multi-item scene, so the whole
      // session needs a multi-capable tier.
      provider = await _providerManager.getBestAvailable(
        AnalysisCapability.imageMulti,
      );
    } catch (_) {
      provider = null;
    }
    if (provider == null) {
      await _sessionLog?.recordNoAi(
        id: sessionId,
        videoPath: videoPath,
        roomId: roomId,
      );
      yield const VideoNoAiConfigured();
      return;
    }

    yield VideoAnalysisStarted(provider.tier);
    await _sessionLog?.begin(
      id: sessionId,
      videoPath: videoPath,
      roomId: roomId,
      providerTier: provider.tier.name,
    );

    // ── Stage 1: extraction ────────────────────────────────────────────
    yield const VideoStageChanged(AnalysisStatus.extracting);
    final frames = <FrameData>[];
    try {
      await for (final frame in _frames(
        videoPath: videoPath,
        config: config,
      )) {
        frames.add(frame);
        yield VideoFrameProgress(
          processed: frames.length,
          total: 0,
          itemsSoFar: 0,
        );
      }
    } catch (e) {
      await _sessionLog?.finish(
        id: sessionId,
        status: 'failed',
        frameCount: frames.length,
        itemsDetected: 0,
      );
      yield VideoAnalysisFailed('$e');
      return;
    }

    // ── Stage 2: quality gate ──────────────────────────────────────────
    yield const VideoStageChanged(AnalysisStatus.selecting);
    final selected = _gate.select(frames, config: config);
    // Only the gate's winners are needed from here on — release every
    // other frame's bytes instead of holding the whole walkthrough in
    // memory for the rest of the run.
    final extractedFrameCount = frames.length;
    frames.clear();
    yield VideoFramesSelected(selected.length);

    // ── Stage 3: per-frame VLM analysis ────────────────────────────────
    yield const VideoStageChanged(AnalysisStatus.analyzing);
    final frameBytes = <int, Uint8List>{
      for (final f in selected) f.index: f.imageBytes,
    };
    final raw = <FrameSuggestion>[];
    var merged = <FrameSuggestion>[];
    var analyzed = 0;
    for (final frame in selected) {
      try {
        final results = await provider.analyzeImageMulti(frame.imageBytes);
        raw.addAll(
          results.map(
            (r) => FrameSuggestion(frameIndex: frame.index, result: r),
          ),
        );
      } catch (_) {
        // One refused frame must not sink the walkthrough.
      }
      analyzed++;
      merged = _merger.merge(raw);
      yield VideoFrameProgress(
        processed: analyzed,
        total: selected.length,
        itemsSoFar: merged.length,
        // The merged partials, review-ready: cancelling mid-run keeps
        // what the completed calls already paid for.
        items: _buildItems(sessionId, merged, frameBytes, config),
      );
    }

    // ── Stage 4: merged, capped, frame-tagged results ──────────────────
    final items = _buildItems(sessionId, merged, frameBytes, config);

    await _sessionLog?.finish(
      id: sessionId,
      status: 'completed',
      frameCount: extractedFrameCount,
      itemsDetected: items.length,
    );
    yield VideoAnalysisCompleted(items);
  }

  List<DetectedObject> _buildItems(
    String sessionId,
    List<FrameSuggestion> merged,
    Map<int, Uint8List> frameBytes,
    AnalysisConfig config,
  ) {
    final capped = merged.take(config.maxObjectsPerSession).toList();
    return <DetectedObject>[
      for (var i = 0; i < capped.length; i++)
        _toDetectedObject(sessionId, i, capped[i], frameBytes),
    ];
  }

  static DetectedObject _toDetectedObject(
    String sessionId,
    int index,
    FrameSuggestion suggestion,
    Map<int, Uint8List> frameBytes,
  ) {
    final r = suggestion.result;
    return DetectedObject(
      id: '$sessionId-$index',
      label: r.itemName.trim().isEmpty ? 'Unidentified item' : r.itemName,
      confidence: r.confidence,
      frameImage: frameBytes[suggestion.frameIndex] ?? Uint8List(0),
      frameIndex: suggestion.frameIndex,
      brand: _nullIfEmpty(r.brand),
      model: _nullIfEmpty(r.model),
      description: _nullIfEmpty(r.description),
      estimatedPrice: r.estimatedPrice,
      category: _nullIfEmpty(r.category),
    );
  }

  static String? _nullIfEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s;
}

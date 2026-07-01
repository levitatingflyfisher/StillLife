import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../data/services/analysis_orchestrator.dart';
import '../../data/services/frame_extractor.dart';
import '../../data/services/video_session_log.dart';
import '../../domain/entities/analysis_session.dart';
import '../../../../services/ml/analysis_provider.dart';

const _uuid = Uuid();

/// The one session-log instance both the orchestrator (begin/finish)
/// and the controller (cancellation) write through.
final videoSessionLogProvider = Provider<VideoSessionLog>(
  (ref) => VideoSessionLog(ref.watch(databaseProvider)),
);

/// The production orchestrator: real ffmpeg extraction seam, the live
/// provider cascade, and session rows written to the database.
final analysisOrchestratorProvider = Provider<AnalysisOrchestrator>((ref) {
  return AnalysisOrchestrator(
    frames: extractVideoFrames,
    providerManager: ref.watch(providerManagerProvider),
    sessionLog: ref.watch(videoSessionLogProvider),
  );
});

/// Main controller for the video analysis session lifecycle.
final videoAnalysisControllerProvider =
    StateNotifierProvider<VideoAnalysisController, AnalysisSession?>((ref) {
      return VideoAnalysisController(ref);
    });

class VideoAnalysisController extends StateNotifier<AnalysisSession?> {
  final Ref _ref;

  /// Session ids the user stopped/cancelled — the event loop bails on
  /// the next event, which cancels the orchestrator's generator.
  final Set<String> _stopped = {};

  VideoAnalysisController(this._ref) : super(null);

  /// Runs the full walkthrough pipeline for [videoPath], mapping
  /// orchestrator events onto the session the processing screen renders.
  ///
  /// The session exists (and confirmation state is reset) before the first
  /// await, so callers can navigate to the processing screen immediately
  /// after invoking this — no flash of "no active session".
  Future<void> runAnalysis({
    required String videoPath,
    String? roomId,
    AnalysisConfig config = const AnalysisConfig(),
  }) async {
    startSession(videoPath, roomId);
    final sessionId = state!.id;
    final orchestrator = _ref.read(analysisOrchestratorProvider);

    try {
      await for (final event in orchestrator.analyze(
        sessionId: sessionId,
        videoPath: videoPath,
        config: config,
        roomId: roomId,
      )) {
        // A newer session may have replaced this one mid-run (user hit
        // Cancel and re-recorded), or THIS session was stopped/cancelled;
        // its events must not clobber the state. Returning from the
        // await-for also cancels the orchestrator's generator, so no
        // further frames are analyzed (or paid for).
        if (!mounted || state?.id != sessionId || _stopped.contains(sessionId)) {
          return;
        }

        state = switch (event) {
          VideoAnalysisStarted(:final tier) => state!.copyWith(
            providerTier: tier,
          ),
          VideoNoAiConfigured() => state!.copyWith(
            status: AnalysisStatus.noAiConfigured,
            completedAt: DateTime.now(),
          ),
          VideoStageChanged(:final stage) => state!.copyWith(status: stage),
          VideoFrameProgress(
            :final processed,
            :final total,
            :final itemsSoFar,
            :final items,
          ) =>
            state!.copyWith(
              processedFrames: processed,
              // ffmpeg discovers the total as it goes during extraction;
              // during analysis the total is the selected-frame count.
              totalFrames: total > 0 ? total : processed,
              itemsSoFar: itemsSoFar,
              // Partial findings land as they merge (analysis stage only),
              // so Stop & Review has something to keep mid-run.
              detectedObjects: total > 0 ? items : null,
            ),
          VideoFramesSelected(:final count) => state!.copyWith(
            selectedFrames: count,
          ),
          VideoAnalysisCompleted(:final items) => state!.copyWith(
            status: AnalysisStatus.reviewing,
            detectedObjects: items,
            itemsSoFar: items.length,
            completedAt: DateTime.now(),
          ),
          VideoAnalysisFailed(:final message) => state!.copyWith(
            status: AnalysisStatus.failed,
            failureMessage: message,
            completedAt: DateTime.now(),
          ),
        };
      }
    } catch (e) {
      if (mounted && state?.id == sessionId) {
        state = state!.copyWith(
          status: AnalysisStatus.failed,
          failureMessage: '$e',
          completedAt: DateTime.now(),
        );
      }
    }
  }

  /// Stops a still-running pipeline but KEEPS the partial findings for
  /// review — the VLM calls that already ran were paid for. The session
  /// row is closed as 'cancelled' (the generator's own finish() can
  /// never run once the event loop abandons it).
  Future<void> stopAndReview() async {
    final session = state;
    if (session == null) return;
    if (session.isProcessing) {
      _stopped.add(session.id);
      await _markCancelled(session);
    }
    updateStatus(AnalysisStatus.reviewing);
  }

  /// Cancels the run and discards the session. The bookkeeping row is
  /// closed as 'cancelled' instead of stranding at 'processing' forever.
  Future<void> cancelAnalysis() async {
    final session = state;
    if (session == null) return;
    if (session.isProcessing) {
      _stopped.add(session.id);
      await _markCancelled(session);
    }
    reset();
  }

  Future<void> _markCancelled(AnalysisSession session) async {
    try {
      await _ref
          .read(videoSessionLogProvider)
          .finish(
            id: session.id,
            status: 'cancelled',
            frameCount: session.processedFrames,
            itemsDetected: session.itemsSoFar,
          );
    } catch (_) {
      // Bookkeeping must never block the user's cancel.
    }
  }

  /// Begin a new analysis session for the given video file.
  void startSession(String videoPath, String? roomId) {
    _stopped.clear();
    state = AnalysisSession(
      id: _uuid.v4(),
      videoPath: videoPath,
      roomId: roomId,
      status: AnalysisStatus.extracting,
      startedAt: DateTime.now(),
    );
  }

  /// Transition the session to a new pipeline stage (used by the review
  /// hand-off buttons; the pipeline itself drives status via events).
  void updateStatus(AnalysisStatus status) {
    if (state == null) return;
    state = state!.copyWith(
      status: status,
      completedAt: status == AnalysisStatus.complete ? DateTime.now() : null,
    );
  }

  /// Clear the session.
  void reset() {
    state = null;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/analysis_session.dart';
import '../../domain/entities/detected_object.dart';

const _uuid = Uuid();

/// Tracks which detected objects the user has confirmed.
final confirmedObjectIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Tracks which detected objects the user has deleted/dismissed.
final deletedObjectIdsProvider = StateProvider<Set<String>>((ref) => {});

/// ID of the detected object currently being edited in ItemEditScreen.
/// Set before navigating; cleared after the edit screen pops.
final reviewEditObjectIdProvider = StateProvider<String?>((ref) => null);

/// Main controller for the video analysis session lifecycle.
final videoAnalysisControllerProvider =
    StateNotifierProvider<VideoAnalysisController, AnalysisSession?>((ref) {
      return VideoAnalysisController(ref);
    });

class VideoAnalysisController extends StateNotifier<AnalysisSession?> {
  final Ref _ref;

  VideoAnalysisController(this._ref) : super(null);

  /// Begin a new analysis session for the given video file.
  void startSession(String videoPath, String? roomId) {
    // Reset confirmation/deletion sets for the new session.
    _ref.read(confirmedObjectIdsProvider.notifier).state = {};
    _ref.read(deletedObjectIdsProvider.notifier).state = {};

    state = AnalysisSession(
      id: _uuid.v4(),
      videoPath: videoPath,
      roomId: roomId,
      status: AnalysisStatus.extracting,
      startedAt: DateTime.now(),
    );
  }

  /// Transition the session to a new pipeline stage.
  void updateStatus(AnalysisStatus status) {
    if (state == null) return;
    state = state!.copyWith(
      status: status,
      completedAt: status == AnalysisStatus.complete ? DateTime.now() : null,
    );
  }

  /// Report frame-level progress.
  void updateProgress(int processed, int total) {
    if (state == null) return;
    state = state!.copyWith(processedFrames: processed, totalFrames: total);
  }

  /// Append a newly detected object to the session.
  void addDetectedObject(DetectedObject obj) {
    if (state == null) return;
    state = state!.copyWith(detectedObjects: [...state!.detectedObjects, obj]);
  }

  /// Remove an object by its ID.
  void removeObject(String objectId) {
    if (state == null) return;
    state = state!.copyWith(
      detectedObjects: state!.detectedObjects
          .where((o) => o.id != objectId)
          .toList(),
    );
    // Also remove from confirmed set if present.
    final confirmed = {..._ref.read(confirmedObjectIdsProvider)};
    confirmed.remove(objectId);
    _ref.read(confirmedObjectIdsProvider.notifier).state = confirmed;
  }

  /// Mark a single object as confirmed.
  void confirmObject(String objectId) {
    final confirmed = {..._ref.read(confirmedObjectIdsProvider)};
    confirmed.add(objectId);
    _ref.read(confirmedObjectIdsProvider.notifier).state = confirmed;

    // Remove from deleted set if it was there.
    final deleted = {..._ref.read(deletedObjectIdsProvider)};
    if (deleted.remove(objectId)) {
      _ref.read(deletedObjectIdsProvider.notifier).state = deleted;
    }
  }

  /// Confirm every detected object in the current session.
  void confirmAll() {
    if (state == null) return;
    final allIds = state!.detectedObjects.map((o) => o.id).toSet();
    final deleted = _ref.read(deletedObjectIdsProvider);
    _ref.read(confirmedObjectIdsProvider.notifier).state = allIds.difference(
      deleted,
    );
  }

  /// Clear the session and all related state.
  void reset() {
    state = null;
    _ref.read(confirmedObjectIdsProvider.notifier).state = {};
    _ref.read(deletedObjectIdsProvider.notifier).state = {};
  }
}

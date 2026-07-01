import 'package:equatable/equatable.dart';

import '../../../../services/ml/analysis_provider.dart';
import 'detected_object.dart';

/// The VLM walkthrough pipeline: extract → select → analyze → review,
/// plus the honest terminal states — a session that cannot run because no
/// AI tier is configured says so instead of spinning forever.
enum AnalysisStatus {
  recording('Recording'),
  extracting('Extracting frames'),
  selecting('Choosing sharp frames'),
  analyzing('Identifying items'),
  reviewing('Ready for review'),
  complete('Complete'),
  noAiConfigured('No AI configured'),
  failed('Analysis failed');

  final String label;
  const AnalysisStatus(this.label);
}

class AnalysisSession extends Equatable {
  final String id;
  final String videoPath;
  final String? roomId;
  final AnalysisStatus status;
  final int totalFrames;
  final int processedFrames;

  /// How many frames survived the quality gate — each one costs exactly
  /// one analysis call, so this number IS the cost disclosure.
  final int selectedFrames;

  /// Running MERGED item count while analysis is still going.
  /// [detectedObjects] carries the merged partial findings during the
  /// analysis stage and the final list on completion.
  final int itemsSoFar;

  final List<DetectedObject> detectedObjects;
  final AnalysisTier providerTier;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// Set when [status] is [AnalysisStatus.failed].
  final String? failureMessage;

  const AnalysisSession({
    required this.id,
    required this.videoPath,
    this.roomId,
    this.status = AnalysisStatus.recording,
    this.totalFrames = 0,
    this.processedFrames = 0,
    this.selectedFrames = 0,
    this.itemsSoFar = 0,
    this.detectedObjects = const [],
    this.providerTier = AnalysisTier.onDevice,
    required this.startedAt,
    this.completedAt,
    this.failureMessage,
  });

  double get progress {
    if (totalFrames == 0) return 0.0;
    return processedFrames / totalFrames;
  }

  bool get isComplete => status == AnalysisStatus.complete;
  bool get isProcessing =>
      status == AnalysisStatus.extracting ||
      status == AnalysisStatus.selecting ||
      status == AnalysisStatus.analyzing;

  int get itemCount => detectedObjects.length;

  Duration? get elapsed {
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  AnalysisSession copyWith({
    AnalysisStatus? status,
    int? totalFrames,
    int? processedFrames,
    int? selectedFrames,
    int? itemsSoFar,
    List<DetectedObject>? detectedObjects,
    AnalysisTier? providerTier,
    DateTime? completedAt,
    String? failureMessage,
  }) {
    return AnalysisSession(
      id: id,
      videoPath: videoPath,
      roomId: roomId,
      status: status ?? this.status,
      totalFrames: totalFrames ?? this.totalFrames,
      processedFrames: processedFrames ?? this.processedFrames,
      selectedFrames: selectedFrames ?? this.selectedFrames,
      itemsSoFar: itemsSoFar ?? this.itemsSoFar,
      detectedObjects: detectedObjects ?? this.detectedObjects,
      providerTier: providerTier ?? this.providerTier,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      failureMessage: failureMessage ?? this.failureMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    status,
    processedFrames,
    selectedFrames,
    itemsSoFar,
    detectedObjects,
  ];
}

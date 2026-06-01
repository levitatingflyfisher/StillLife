import 'package:equatable/equatable.dart';

import '../../../../services/ml/analysis_provider.dart';
import 'detected_object.dart';

enum AnalysisStatus {
  recording('Recording'),
  extracting('Extracting frames'),
  detecting('Detecting objects'),
  tracking('Tracking objects'),
  selecting('Selecting best frames'),
  classifying('Classifying items'),
  enhancing('Enhancing with AI'),
  reviewing('Ready for review'),
  complete('Complete');

  final String label;
  const AnalysisStatus(this.label);

  int get stageIndex => index;
  static int get totalStages => values.length - 1; // exclude 'complete'
}

class AnalysisSession extends Equatable {
  final String id;
  final String videoPath;
  final String? roomId;
  final AnalysisStatus status;
  final int totalFrames;
  final int processedFrames;
  final List<DetectedObject> detectedObjects;
  final AnalysisTier providerTier;
  final DateTime startedAt;
  final DateTime? completedAt;

  const AnalysisSession({
    required this.id,
    required this.videoPath,
    this.roomId,
    this.status = AnalysisStatus.recording,
    this.totalFrames = 0,
    this.processedFrames = 0,
    this.detectedObjects = const [],
    this.providerTier = AnalysisTier.onDevice,
    required this.startedAt,
    this.completedAt,
  });

  double get progress {
    if (totalFrames == 0) return 0.0;
    return processedFrames / totalFrames;
  }

  bool get isComplete => status == AnalysisStatus.complete;
  bool get isProcessing =>
      status != AnalysisStatus.recording &&
      status != AnalysisStatus.reviewing &&
      status != AnalysisStatus.complete;

  int get itemCount => detectedObjects.length;

  Duration? get elapsed {
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  AnalysisSession copyWith({
    AnalysisStatus? status,
    int? totalFrames,
    int? processedFrames,
    List<DetectedObject>? detectedObjects,
    AnalysisTier? providerTier,
    DateTime? completedAt,
  }) {
    return AnalysisSession(
      id: id,
      videoPath: videoPath,
      roomId: roomId,
      status: status ?? this.status,
      totalFrames: totalFrames ?? this.totalFrames,
      processedFrames: processedFrames ?? this.processedFrames,
      detectedObjects: detectedObjects ?? this.detectedObjects,
      providerTier: providerTier ?? this.providerTier,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, status, processedFrames, detectedObjects];
}

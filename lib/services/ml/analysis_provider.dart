import 'dart:typed_data';

/// The 4 tiers of LLM analysis providers.
enum AnalysisTier {
  onDevice('On-Device ML'),
  localLlm('Local LLM (Ollama)'),
  cloudApi('Cloud API'),
  hosted('Still Life Hosted');

  final String label;
  const AnalysisTier(this.label);
}

/// Result of an LLM analysis on an image.
class AnalysisResult {
  final String itemName;
  final String? brand;
  final String? model;
  final String description;
  final String category;
  final double? estimatedPrice;
  final double confidence;
  final Map<String, dynamic> rawResponse;

  const AnalysisResult({
    required this.itemName,
    this.brand,
    this.model,
    required this.description,
    required this.category,
    this.estimatedPrice,
    required this.confidence,
    this.rawResponse = const {},
  });
}

/// Progress information during video analysis.
class AnalysisProgress {
  final int currentFrame;
  final int totalFrames;
  final int itemsDetected;
  final String stage;
  final double progress;

  const AnalysisProgress({
    required this.currentFrame,
    required this.totalFrames,
    required this.itemsDetected,
    required this.stage,
    required this.progress,
  });
}

/// Configuration for video analysis pipeline.
class AnalysisConfig {
  final double framesPerSecond;
  final double blurThreshold; // Laplacian variance minimum
  final double confidenceThreshold; // YOLO detection minimum
  final double iouTrackingThreshold; // IoU for same-object tracking
  final int maxObjectsPerSession;
  final bool enhanceWithLlm;
  final AnalysisTier? preferredTier;

  const AnalysisConfig({
    this.framesPerSecond = 2.0,
    this.blurThreshold = 100.0,
    this.confidenceThreshold = 0.4,
    this.iouTrackingThreshold = 0.3,
    this.maxObjectsPerSession = 200,
    this.enhanceWithLlm = true,
    this.preferredTier,
  });
}

/// All 4 LLM tiers implement this interface.
abstract class AnalysisProvider {
  String get name;
  AnalysisTier get tier;

  /// Check if this provider is currently available.
  Future<bool> isAvailable();

  /// Analyze a single image and return item identification.
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  });

  /// Analyze a video file and stream progress updates.
  Stream<AnalysisProgress> analyzeVideo({
    required String videoPath,
    required AnalysisConfig config,
  });
}

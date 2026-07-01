import 'dart:typed_data';

/// Anthropic model id used by every Claude-backed analysis path (BYO
/// Claude tier, hosted /v1/messages passthrough, item chat).
///
/// A current ALIAS, deliberately not a dated snapshot: the previous pin
/// ('claude-sonnet-4-20250514') was deprecated with retirement announced,
/// which would have 404'd every photo/voice/receipt analysis with no
/// settings-level fix. Matches [kAppraiserDefaultModel]'s alias policy.
const String kDefaultClaudeAnalysisModel = 'claude-sonnet-4-6';

/// What kinds of analysis calls a provider can serve. The cascade matches
/// each call to a capability so a partial provider (e.g. an on-device
/// image labeler with no text model) is never handed a call it would
/// throw on.
enum AnalysisCapability {
  /// Single-item photo analysis ([AnalysisProvider.analyzeImage]).
  image,

  /// Multi-item shelf/room photo analysis
  /// ([AnalysisProvider.analyzeImageMulti]).
  imageMulti,

  /// Text-only calls — both [AnalysisProvider.analyzeText] and
  /// [AnalysisProvider.completeText] need a general text model.
  text,
}

/// The 4 tiers of LLM analysis providers.
enum AnalysisTier {
  onDevice('On-Device ML'),
  localLlm('Local LLM (Ollama)'),
  cloudApi('Cloud API'),
  hosted('Still Life Hosted');

  final String label;
  const AnalysisTier(this.label);
}

/// Default tier priority: quality-first, with on-device LAST. The
/// on-device tier is always available on Android (bundled labeler), so
/// putting it first would silently downgrade every configured user's
/// photo analysis to coarse labels. As the floor, it only answers when
/// nothing better is configured; privacy-first users can drag it to the
/// top in settings.
const List<AnalysisTier> kDefaultTierPriority = [
  AnalysisTier.localLlm,
  AnalysisTier.cloudApi,
  AnalysisTier.hosted,
  AnalysisTier.onDevice,
];

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

/// Configuration for the video-walkthrough analysis pipeline.
class AnalysisConfig {
  final double framesPerSecond;
  final double blurThreshold; // Laplacian variance minimum
  final int maxObjectsPerSession;

  /// How many frames survive the quality gate and get an analysis call.
  /// Every frame is one VLM call, so this is the cost/coverage dial.
  final int topKFrames;

  const AnalysisConfig({
    this.framesPerSecond = 2.0,
    this.blurThreshold = 100.0,
    this.maxObjectsPerSession = 200,
    this.topKFrames = 12,
  });
}

/// Optional context accompanying a text analysis request. Providers may
/// fold it into their prompt (e.g. a label the user already assigned).
class AnalysisContext {
  final String? existingLabel;

  const AnalysisContext({this.existingLabel});
}

/// All 4 LLM tiers implement this interface.
abstract class AnalysisProvider {
  String get name;
  AnalysisTier get tier;

  /// Which call types this provider can serve. Defaults to all of them —
  /// the four full-LLM tiers do everything. A partial provider (vision-only
  /// on-device labeler) overrides this so the cascade never routes it a
  /// call it cannot handle.
  Set<AnalysisCapability> get capabilities => const {
    AnalysisCapability.image,
    AnalysisCapability.imageMulti,
    AnalysisCapability.text,
  };

  /// Check if this provider is currently available.
  Future<bool> isAvailable();

  /// Analyze a single image and return item identification.
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  });

  /// Analyze one image containing MANY items (a shelf, a room corner) and
  /// return one result per distinct item found, capped at kMultiItemCap
  /// (multi_item_parser.dart). Malformed model output degrades to fewer
  /// (or zero) results — never a crash.
  Future<List<AnalysisResult>> analyzeImageMulti(
    Uint8List imageBytes, {
    AnalysisContext? context,
  });

  /// Analyze a free-text prompt (no image) and return item identification.
  /// Used by voice intake and other text-only extraction flows.
  Future<AnalysisResult> analyzeText(String prompt, {AnalysisContext? context});

  /// Send a raw text prompt and return the model's raw reply, with NO
  /// item-analysis parsing applied. The seam for flows whose reply is not
  /// an [AnalysisResult] — receipt structuring parses its own shape.
  Future<String> completeText(String prompt, {int maxTokens = 1000});
}

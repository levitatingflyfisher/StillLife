import 'dart:typed_data';
import 'package:still_life/features/inventory/domain/entities/item_suggestion.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/provider_manager.dart';

/// Typed result of a photo/voice analysis attempt so the UI can tell
/// "no AI configured" (say so, fall through to the manual form) apart
/// from a transient failure — instead of a null/stub suggestion or an
/// exception blob.
sealed class AnalysisOutcome {
  const AnalysisOutcome();
}

/// The provider chain produced a usable suggestion.
final class AnalysisSuggestion extends AnalysisOutcome {
  final ItemSuggestion suggestion;
  const AnalysisSuggestion(this.suggestion);
}

/// A shelf/room photo produced one suggestion per item found (possibly
/// zero — an honest "nothing identified" the caller decides how to
/// degrade, never an error dressed up as data).
final class ShelfSuggestions extends AnalysisOutcome {
  final List<ItemSuggestion> suggestions;
  const ShelfSuggestions(this.suggestions);
}

/// No AI tier is configured/available. Not an error — the UI should
/// explain and fall through to manual entry.
final class NoAiConfigured extends AnalysisOutcome {
  const NoAiConfigured();
}

/// A configured provider was found but the analysis failed.
final class AnalysisFailed extends AnalysisOutcome {
  final String message;
  const AnalysisFailed(this.message);
}

class ItemPhotoAnalysisService {
  final ProviderManager _manager;

  ItemPhotoAnalysisService(this._manager);

  /// Analyze a photo (raw bytes) into a typed [AnalysisOutcome].
  Future<AnalysisOutcome> analyzePhoto(Uint8List imageBytes) async {
    final AnalysisProvider? provider;
    try {
      provider = await _manager.getBestAvailable(AnalysisCapability.image);
    } catch (e) {
      return AnalysisFailed('$e');
    }
    if (provider == null) return const NoAiConfigured();
    try {
      final result = await provider.analyzeImage(imageBytes: imageBytes);
      return AnalysisSuggestion(_toSuggestion(result));
    } catch (e) {
      return AnalysisFailed('$e');
    }
  }

  /// Analyze a shelf/room photo (raw bytes) into one suggestion per item
  /// found — [ShelfSuggestions] on success, the usual typed outcomes when
  /// no tier is configured or the analysis fails.
  Future<AnalysisOutcome> analyzeShelfPhoto(Uint8List imageBytes) async {
    final AnalysisProvider? provider;
    try {
      provider = await _manager.getBestAvailable(
        AnalysisCapability.imageMulti,
      );
    } catch (e) {
      return AnalysisFailed('$e');
    }
    if (provider == null) return const NoAiConfigured();
    try {
      final results = await provider.analyzeImageMulti(imageBytes);
      return ShelfSuggestions(
        results.map(_toSuggestion).toList(growable: false),
      );
    } catch (e) {
      return AnalysisFailed('$e');
    }
  }

  /// Send a voice transcript through the LLM chain as a text-only
  /// extraction prompt, returning a typed [AnalysisOutcome].
  Future<AnalysisOutcome> analyzeVoice(String transcript) async {
    final AnalysisProvider? provider;
    try {
      provider = await _manager.getBestAvailable(AnalysisCapability.text);
    } catch (e) {
      return AnalysisFailed('$e');
    }
    if (provider == null) return const NoAiConfigured();
    try {
      final result = await provider.analyzeText(_voicePrompt(transcript));
      return AnalysisSuggestion(_toSuggestion(result));
    } catch (e) {
      return AnalysisFailed('$e');
    }
  }

  static ItemSuggestion _toSuggestion(AnalysisResult result) => ItemSuggestion(
    name: result.itemName.isEmpty ? null : result.itemName,
    brand: _nullIfEmpty(result.brand),
    model: _nullIfEmpty(result.model),
    categoryName: result.category.isEmpty ? null : result.category,
    estimatedValue: result.estimatedPrice,
    notes: result.description.isEmpty ? null : result.description,
    confidence: result.confidence,
  );

  static String? _nullIfEmpty(String? s) =>
      (s == null || s.isEmpty) ? null : s;

  /// Terse JSON-extraction prompt. Field names match what the provider
  /// response parsers already understand.
  static String _voicePrompt(String transcript) =>
      'Extract details of a household item from this spoken description. '
      'Respond ONLY with compact JSON, no markdown: '
      '{"name": string, "brand": string or null, "model": string or null, '
      '"category": one of [Electronics, Furniture, '
      'Appliances, Clothing, Tools, Sports, Books, Kitchenware, Other], '
      '"estimatedRetailPrice": number or null, '
      '"description": brief note or null}. '
      'Description: "$transcript"';
}

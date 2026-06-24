import 'dart:convert';
import 'dart:typed_data';
import 'package:still_life/features/inventory/domain/entities/item_suggestion.dart';
import 'package:still_life/services/ml/provider_manager.dart';

class ItemPhotoAnalysisService {
  final ProviderManager _manager;

  ItemPhotoAnalysisService(this._manager);

  /// Analyze a photo (raw bytes) and return a suggestion, or null if
  /// no LLM is configured or the call fails.
  Future<ItemSuggestion?> analyzePhoto(Uint8List imageBytes) async {
    try {
      final provider = await _manager.getBestAvailable();
      if (provider == null) return null;
      final result = await provider.analyzeImage(imageBytes: imageBytes);
      return ItemSuggestion(
        name: result.itemName.isEmpty ? null : result.itemName,
        categoryName: result.category.isEmpty ? null : result.category,
        estimatedValue: result.estimatedPrice,
        notes: result.description.isEmpty ? null : result.description,
      );
    } catch (_) {
      return null;
    }
  }

  /// Send a voice transcript through the LLM chain using a minimal image
  /// and an extraction prompt in existingLabel. Returns null on failure.
  Future<ItemSuggestion?> analyzeVoice(String transcript) async {
    try {
      final provider = await _manager.getBestAvailable();
      if (provider == null) return null;
      final result = await provider.analyzeImage(
        imageBytes: _minimalPng(),
        existingLabel:
            'Extract item name, category (one of: Electronics, Furniture, '
            'Appliances, Clothing, Tools, Sports, Books, Kitchenware, Other), '
            'and estimated value in USD from this spoken description. '
            'Description: "$transcript"',
      );
      return ItemSuggestion(
        name: result.itemName.isEmpty ? null : result.itemName,
        categoryName: result.category.isEmpty ? null : result.category,
        estimatedValue: result.estimatedPrice,
        notes: result.description.isEmpty ? null : result.description,
      );
    } catch (_) {
      return null;
    }
  }

  // Minimal 1x1 transparent PNG — satisfies the imageBytes parameter
  // without requiring image_picker in the service layer.
  static Uint8List _minimalPng() {
    const b64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
    return base64Decode(b64);
  }
}

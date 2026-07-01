import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/multi_item_parser.dart';
import 'package:still_life/services/ml/single_item_parser.dart';

/// Tier 2: Local LLM provider via Ollama.
///
/// Connects to a local Ollama instance for vision-capable LLM analysis.
/// Supports configurable model (defaults to llava) and base URL.
class OllamaProvider extends AnalysisProvider {
  final Dio _dio;
  final String baseUrl;
  final String model;

  static const Duration _timeout = Duration(seconds: 30);

  OllamaProvider({
    required Dio dio,
    this.baseUrl = 'http://localhost:11434',
    this.model = 'llava',
  }) : _dio = dio;

  @override
  String get name => 'Ollama ($model)';

  @override
  AnalysisTier get tier => AnalysisTier.localLlm;

  /// Checks whether Ollama is running by querying its tags endpoint.
  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get<dynamic>(
        '$baseUrl/api/tags',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Sends an image to Ollama's generate endpoint for vision analysis.
  @override
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  }) async {
    final imageBase64 = await compute(base64Encode, imageBytes);

    final prompt = existingLabel != null
        ? 'This item has been labeled "$existingLabel". $kSingleItemAnalysisPrompt'
        : kSingleItemAnalysisPrompt;

    final requestBody = <String, dynamic>{
      'model': model,
      'prompt': prompt,
      'images': [imageBase64],
      'stream': false,
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/generate',
        data: requestBody,
        options: Options(
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
          contentType: 'application/json',
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const AnalysisException('Empty response from Ollama');
      }

      final responseText = data['response'] as String? ?? '';
      return _parseResponse(responseText);
    } on DioException catch (e) {
      throw AnalysisException(
        'Ollama request failed: ${e.message ?? e.type.name}',
      );
    }
  }

  /// Sends a shelf/room photo to Ollama's generate endpoint with the
  /// multi-item prompt; parses the reply defensively into 0..25 results.
  @override
  Future<List<AnalysisResult>> analyzeImageMulti(
    Uint8List imageBytes, {
    AnalysisContext? context,
  }) async {
    final label = context?.existingLabel;
    final prompt = label != null
        ? 'This photo has been labeled "$label". $kMultiItemAnalysisPrompt'
        : kMultiItemAnalysisPrompt;

    final requestBody = <String, dynamic>{
      'model': model,
      'prompt': prompt,
      'images': [await compute(base64Encode, imageBytes)],
      'stream': false,
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/generate',
        data: requestBody,
        options: Options(
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
          contentType: 'application/json',
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const AnalysisException('Empty response from Ollama');
      }

      return parseMultiItemResponse(
        data['response'] as String? ?? '',
        defaultConfidence: 0.7,
      );
    } on DioException catch (e) {
      throw AnalysisException(
        'Ollama request failed: ${e.message ?? e.type.name}',
      );
    }
  }

  /// Sends a text-only prompt to Ollama's generate endpoint. No image is
  /// attached — this is the seam voice intake uses for transcript extraction.
  @override
  Future<AnalysisResult> analyzeText(
    String prompt, {
    AnalysisContext? context,
  }) async {
    final label = context?.existingLabel;
    final fullPrompt = label != null
        ? 'This item has been labeled "$label". $prompt'
        : prompt;

    final requestBody = <String, dynamic>{
      'model': model,
      'prompt': fullPrompt,
      'stream': false,
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/generate',
        data: requestBody,
        options: Options(
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
          contentType: 'application/json',
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const AnalysisException('Empty response from Ollama');
      }

      final responseText = data['response'] as String? ?? '';
      return _parseResponse(responseText);
    } on DioException catch (e) {
      throw AnalysisException(
        'Ollama request failed: ${e.message ?? e.type.name}',
      );
    }
  }

  /// Sends a raw text prompt to Ollama's generate endpoint and returns the
  /// model's reply verbatim — no item-analysis parsing applied.
  @override
  Future<String> completeText(String prompt, {int maxTokens = 1000}) async {
    final requestBody = <String, dynamic>{
      'model': model,
      'prompt': prompt,
      'stream': false,
      'options': {'num_predict': maxTokens},
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/generate',
        data: requestBody,
        options: Options(
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
          contentType: 'application/json',
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const AnalysisException('Empty response from Ollama');
      }
      return data['response'] as String? ?? '';
    } on DioException catch (e) {
      throw AnalysisException(
        'Ollama request failed: ${e.message ?? e.type.name}',
      );
    }
  }

  /// Parses the LLM response text, trying JSON first then falling back
  /// to basic text extraction.
  AnalysisResult _parseResponse(String responseText) {
    // Try to extract JSON from the response (may be wrapped in markdown fences)
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);

    if (jsonMatch != null) {
      try {
        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return AnalysisResult(
          itemName: json['name'] as String? ?? 'Unknown Item',
          brand: json['brand'] as String?,
          model: json['model'] as String?,
          description: json['description'] as String? ?? responseText,
          category: json['category'] as String? ?? 'Other',
          estimatedPrice: _parsePrice(json['estimatedRetailPrice']),
          confidence: 0.7,
          rawResponse: json,
        );
      } on FormatException {
        // Fall through to text extraction
      }
    }

    // Fallback: treat the entire response as a description
    return AnalysisResult(
      itemName: _extractField(responseText, 'name') ?? 'Unknown Item',
      description: responseText.trim(),
      category: _extractField(responseText, 'category') ?? 'Other',
      confidence: 0.4,
      rawResponse: {'raw_text': responseText},
    );
  }

  /// Attempts to extract a named field from unstructured text.
  String? _extractField(String text, String field) {
    final pattern = RegExp(
      '$field[:\\s]+["\']?([^"\'\\n,}]+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  /// Parses a price value that may be a number or string.
  double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    }
    return null;
  }
}

/// Exception thrown when analysis fails.
class AnalysisException implements Exception {
  final String message;
  const AnalysisException(this.message);

  @override
  String toString() => 'AnalysisException: $message';
}

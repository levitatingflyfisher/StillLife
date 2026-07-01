import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/image_media_type.dart';
import 'package:still_life/services/ml/multi_item_parser.dart';
import 'package:still_life/services/ml/ollama_provider.dart'
    show AnalysisException;

/// Thrown when the hosted backend rejects our bearer (HTTP 401). The
/// orchestrator catches this and cascades to the next available tier.
class AuthRequiredException implements Exception {
  final String message;
  const AuthRequiredException(this.message);
  @override
  String toString() => 'AuthRequiredException: $message';
}

/// Thrown when the hosted backend refuses the request due to the caller
/// exceeding the monthly token cap (HTTP 429 with `quota_exceeded`). Not
/// retryable — callers should surface UpgradeCta or fall back.
class QuotaExceededException implements Exception {
  final String message;
  const QuotaExceededException(this.message);
  @override
  String toString() => 'QuotaExceededException: $message';
}

/// Tier 4: Still Life hosted analysis service.
///
/// Bearer is supplied via `apiKeyProvider` (async) so rotations in
/// secure storage are picked up on every request without recreating the
/// provider. 401 fires `onUnauthorized` (fire-and-forget) and throws
/// `AuthRequiredException`; 429 throws `QuotaExceededException`; 503
/// retries with exponential backoff before throwing `AnalysisException`.
class HostedProvider extends AnalysisProvider {
  final Dio _dio;
  final String baseUrl;
  final Future<String> Function() apiKeyProvider;
  final Future<void> Function()? onUnauthorized;

  /// Maximum number of retry attempts on 503 responses.
  final int maxRetries;

  HostedProvider({
    required Dio dio,
    required this.baseUrl,
    required this.apiKeyProvider,
    this.onUnauthorized,
    this.maxRetries = 3,
  }) : _dio = dio;

  @override
  String get name => 'Still Life Hosted';

  @override
  AnalysisTier get tier => AnalysisTier.hosted;

  /// Available if a base URL is configured, a bearer is configured, and
  /// `/v1/account` returns 200. An empty [baseUrl] means the hosted
  /// backend is not configured — fail closed, attempt no HTTP.
  @override
  Future<bool> isAvailable() async {
    if (baseUrl.isEmpty) return false;
    final key = await apiKeyProvider();
    if (key.isEmpty) return false;
    try {
      final r = await _dio.get<dynamic>(
        '$baseUrl/v1/account',
        options: Options(
          headers: {'Authorization': 'Bearer $key'},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  }) async {
    final body = <String, dynamic>{
      'image': await compute(base64Encode, imageBytes),
      'existing_label': ?existingLabel,
      if (contextFrame != null)
        'context_frame': await compute(base64Encode, contextFrame),
    };
    return _postWithRetry('/api/v1/analyze', body, _parseResponse);
  }

  /// Analyzes a free-text prompt through the hosted `/v1/messages`
  /// Anthropic passthrough (no image). Same auth/quota error mapping as
  /// [analyzeImage].
  @override
  Future<AnalysisResult> analyzeText(
    String prompt, {
    AnalysisContext? context,
  }) async {
    final label = context?.existingLabel;
    final fullPrompt = label != null
        ? 'This item has been labeled "$label". $prompt'
        : prompt;
    final body = <String, dynamic>{
      'model': kDefaultClaudeAnalysisModel,
      'max_tokens': 500,
      'messages': [
        {'role': 'user', 'content': fullPrompt},
      ],
    };
    return _postWithRetry('/v1/messages', body, _parseMessagesText);
  }

  /// Analyzes one shelf/room photo into 0..25 per-item results through
  /// the hosted `/v1/messages` Anthropic passthrough — the photo rides as
  /// a base64 image block next to the shared multi-item prompt. Same
  /// auth/quota error mapping as [analyzeImage].
  @override
  Future<List<AnalysisResult>> analyzeImageMulti(
    Uint8List imageBytes, {
    AnalysisContext? context,
  }) async {
    final label = context?.existingLabel;
    final prompt = label != null
        ? 'This photo has been labeled "$label". $kMultiItemAnalysisPrompt'
        : kMultiItemAnalysisPrompt;
    final body = <String, dynamic>{
      'model': kDefaultClaudeAnalysisModel,
      'max_tokens': kMultiItemMaxTokens,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                // Sniffed: walkthrough frames are PNGs; a declared-JPEG
                // PNG 400s on the Anthropic passthrough. The encode runs
                // off the UI isolate — the walkthrough loop animates
                // over these calls.
                'media_type': detectImageMediaType(imageBytes),
                'data': await compute(base64Encode, imageBytes),
              },
            },
            {'type': 'text', 'text': prompt},
          ],
        },
      ],
    };
    return _postWithRetry(
      '/v1/messages',
      body,
      (d) => parseMultiItemResponse(_messagesText(d), defaultConfidence: 0.85),
    );
  }

  /// Sends a raw text prompt through the hosted `/v1/messages` Anthropic
  /// passthrough and returns the reply text verbatim — no item-analysis
  /// parsing applied. Same auth/quota error mapping as [analyzeImage].
  @override
  Future<String> completeText(String prompt, {int maxTokens = 1000}) async {
    final body = <String, dynamic>{
      'model': kDefaultClaudeAnalysisModel,
      'max_tokens': maxTokens,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    };
    return _postWithRetry('/v1/messages', body, _messagesText);
  }

  Future<T> _postWithRetry<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parse,
  ) async {
    if (baseUrl.isEmpty) {
      throw const AnalysisException(
        'Hosted service is not configured (no HOSTED_BASE_URL).',
      );
    }
    DioException? last;
    for (var i = 0; i < maxRetries; i++) {
      try {
        final bearer = await apiKeyProvider();
        final r = await _dio.post<Map<String, dynamic>>(
          '$baseUrl$path',
          data: body,
          options: Options(
            headers: {
              'Authorization': 'Bearer $bearer',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );
        if (r.data == null) {
          throw const AnalysisException('Empty response from hosted service');
        }
        return parse(r.data!);
      } on DioException catch (e) {
        last = e;
        final code = e.response?.statusCode;
        if (code == 401) {
          // Fire-and-forget the callback so the auth layer can clear the
          // stored bearer / invalidate accountProvider.
          if (onUnauthorized != null) {
            // ignore: unawaited_futures
            onUnauthorized!();
          }
          throw AuthRequiredException(
            e.response?.data is Map
                ? (e.response!.data as Map)['error']?.toString() ??
                      'unauthenticated'
                : 'unauthenticated',
          );
        }
        if (code == 429) {
          throw QuotaExceededException(
            e.response?.data is Map
                ? (e.response!.data as Map)['error']?.toString() ?? 'quota'
                : 'quota',
          );
        }
        final retryable = code == 503;
        if (!retryable || i == maxRetries - 1) break;
        // Exponential backoff: 1s, 2s, 4s ...
        await Future<void>.delayed(
          Duration(milliseconds: pow(2, i).toInt() * 1000),
        );
      }
    }
    throw AnalysisException(
      'Hosted service request failed after $maxRetries attempts: '
      '${last?.message ?? 'unknown error'}',
    );
  }

  /// Parses an Anthropic Messages envelope from the hosted passthrough:
  /// concatenates the text blocks, then extracts compact JSON with a
  /// guarded decode — malformed model output degrades to a low-confidence
  /// raw-text result instead of crashing.
  AnalysisResult _parseMessagesText(Map<String, dynamic> d) {
    final text = _messagesText(d);

    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      try {
        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return AnalysisResult(
          itemName: json['name'] as String? ?? 'Unknown Item',
          brand: json['brand'] as String?,
          model: json['model'] as String?,
          description: json['description'] as String? ?? text,
          category: json['category'] as String? ?? 'Other',
          estimatedPrice: _parsePrice(json['estimatedRetailPrice']),
          confidence: 0.85,
          rawResponse: json,
        );
      } on FormatException {
        // Fall through to the raw-text fallback.
      }
    }

    return AnalysisResult(
      itemName: 'Unknown Item',
      description: text.trim(),
      category: 'Other',
      confidence: 0.4,
      rawResponse: {'raw_text': text},
    );
  }

  /// Concatenates the text blocks of an Anthropic Messages envelope.
  String _messagesText(Map<String, dynamic> d) {
    final blocks = d['content'] as List<dynamic>?;
    return blocks == null
        ? ''
        : blocks
              .whereType<Map<String, dynamic>>()
              .where((b) => b['type'] == 'text')
              .map((b) => b['text'] as String? ?? '')
              .join();
  }

  AnalysisResult _parseResponse(Map<String, dynamic> d) => AnalysisResult(
    itemName:
        d['item_name'] as String? ?? d['name'] as String? ?? 'Unknown Item',
    brand: d['brand'] as String?,
    model: d['model'] as String?,
    description: d['description'] as String? ?? '',
    category: d['category'] as String? ?? 'Other',
    estimatedPrice: _parsePrice(
      d['estimated_price'] ?? d['estimatedRetailPrice'],
    ),
    confidence: (d['confidence'] as num?)?.toDouble() ?? 0.8,
    rawResponse: d,
  );

  double? _parsePrice(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v.replaceAll(RegExp(r'[^\d.]'), ''));
    }
    return null;
  }
}

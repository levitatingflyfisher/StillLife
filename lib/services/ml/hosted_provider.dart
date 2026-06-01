import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
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
class HostedProvider implements AnalysisProvider {
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

  /// Available if a bearer is configured and `/v1/account` returns 200.
  @override
  Future<bool> isAvailable() async {
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
      'image': base64Encode(imageBytes),
      'existing_label': ?existingLabel,
      if (contextFrame != null) 'context_frame': base64Encode(contextFrame),
    };
    return _postWithRetry(body);
  }

  /// Video analysis is not directly supported. Use the orchestrator.
  @override
  Stream<AnalysisProgress> analyzeVideo({
    required String videoPath,
    required AnalysisConfig config,
  }) {
    throw UnsupportedError(
      'Hosted provider does not support direct video analysis. '
      'Use the analysis orchestrator for video processing.',
    );
  }

  Future<AnalysisResult> _postWithRetry(Map<String, dynamic> body) async {
    DioException? last;
    for (var i = 0; i < maxRetries; i++) {
      try {
        final bearer = await apiKeyProvider();
        final r = await _dio.post<Map<String, dynamic>>(
          '$baseUrl/api/v1/analyze',
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
        return _parseResponse(r.data!);
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

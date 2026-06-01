import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/ollama_provider.dart'
    show AnalysisException;

/// Which cloud vision API to use.
enum CloudApiType {
  openai('OpenAI Vision'),
  claude('Claude Vision');

  final String label;
  const CloudApiType(this.label);
}

/// Tier 3: Cloud API provider supporting OpenAI Vision and Claude Vision.
class CloudApiProvider implements AnalysisProvider {
  final Dio _dio;
  final String apiKey;
  final CloudApiType apiType;

  /// Minimum delay between successive API calls for rate limiting.
  final Duration rateLimitDelay;

  DateTime? _lastCallTime;

  static const String _openaiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _claudeUrl = 'https://api.anthropic.com/v1/messages';

  static const String _analysisPrompt = '''
Analyze this image of a household item. Respond ONLY with a JSON object (no markdown, no explanation) with these fields:
{
  "name": "item name",
  "brand": "brand name or null",
  "model": "model number/name or null",
  "description": "brief description of the item",
  "category": "one of: Electronics, Furniture, Appliance, Clothing, Kitchenware, Decor, Tool, Book, Toy, Sporting Goods, Jewelry, Art, Musical Instrument, Other",
  "estimatedRetailPrice": estimated price as a number or null
}
''';

  CloudApiProvider({
    required Dio dio,
    required this.apiKey,
    required this.apiType,
    this.rateLimitDelay = const Duration(milliseconds: 500),
  }) : _dio = dio;

  @override
  String get name => apiType.label;

  @override
  AnalysisTier get tier => AnalysisTier.cloudApi;

  /// Available if an API key has been configured.
  @override
  Future<bool> isAvailable() async {
    return apiKey.isNotEmpty;
  }

  @override
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  }) async {
    await _enforceRateLimit();

    final prompt = existingLabel != null
        ? 'This item has been labeled "$existingLabel". $_analysisPrompt'
        : _analysisPrompt;

    return switch (apiType) {
      CloudApiType.openai => _analyzeWithOpenAI(imageBytes, prompt),
      CloudApiType.claude => _analyzeWithClaude(imageBytes, prompt),
    };
  }

  /// Video analysis is not directly supported. Use the orchestrator.
  @override
  Stream<AnalysisProgress> analyzeVideo({
    required String videoPath,
    required AnalysisConfig config,
  }) {
    throw UnsupportedError(
      'Cloud API provider does not support direct video analysis. '
      'Use the analysis orchestrator for video processing.',
    );
  }

  // ---------------------------------------------------------------------------
  // OpenAI Vision
  // ---------------------------------------------------------------------------

  Future<AnalysisResult> _analyzeWithOpenAI(
    Uint8List imageBytes,
    String prompt,
  ) async {
    final imageBase64 = base64Encode(imageBytes);

    final requestBody = <String, dynamic>{
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$imageBase64',
                'detail': 'high',
              },
            },
          ],
        },
      ],
      'max_tokens': 500,
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _openaiUrl,
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const AnalysisException('Empty response from OpenAI');
      }

      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw const AnalysisException('No choices in OpenAI response');
      }

      final message = choices[0] as Map<String, dynamic>;
      final content =
          (message['message'] as Map<String, dynamic>)['content'] as String;
      return _parseJsonResponse(content);
    } on DioException catch (e) {
      throw AnalysisException(
        'OpenAI request failed: ${e.message ?? e.type.name}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Claude Vision
  // ---------------------------------------------------------------------------

  Future<AnalysisResult> _analyzeWithClaude(
    Uint8List imageBytes,
    String prompt,
  ) async {
    final imageBase64 = base64Encode(imageBytes);

    final requestBody = <String, dynamic>{
      'model': 'claude-sonnet-4-20250514',
      'max_tokens': 500,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': imageBase64,
              },
            },
            {'type': 'text', 'text': prompt},
          ],
        },
      ],
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _claudeUrl,
        data: requestBody,
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const AnalysisException('Empty response from Claude');
      }

      final contentBlocks = data['content'] as List<dynamic>?;
      if (contentBlocks == null || contentBlocks.isEmpty) {
        throw const AnalysisException('No content in Claude response');
      }

      final textBlock =
          contentBlocks.firstWhere(
                (block) => (block as Map<String, dynamic>)['type'] == 'text',
                orElse: () => throw const AnalysisException(
                  'No text block in Claude response',
                ),
              )
              as Map<String, dynamic>;

      final text = textBlock['text'] as String;
      return _parseJsonResponse(text);
    } on DioException catch (e) {
      throw AnalysisException(
        'Claude request failed: ${e.message ?? e.type.name}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  /// Enforces minimum delay between API calls for rate limiting.
  Future<void> _enforceRateLimit() async {
    if (_lastCallTime != null) {
      final elapsed = DateTime.now().difference(_lastCallTime!);
      if (elapsed < rateLimitDelay) {
        await Future<void>.delayed(rateLimitDelay - elapsed);
      }
    }
    _lastCallTime = DateTime.now();
  }

  /// Parses a JSON response from either API into an AnalysisResult.
  AnalysisResult _parseJsonResponse(String responseText) {
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
          confidence: 0.85,
          rawResponse: json,
        );
      } on FormatException {
        // Fall through
      }
    }

    return AnalysisResult(
      itemName: 'Unknown Item',
      description: responseText.trim(),
      category: 'Other',
      confidence: 0.4,
      rawResponse: {'raw_text': responseText},
    );
  }

  double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Raw Anthropic Messages passthrough (Phase 23)
  // ---------------------------------------------------------------------------

  /// Sends a raw Anthropic Messages body to `/v1/messages` using the stored
  /// BYO API key. Used by the Appraiser + item-chat features when the hosted
  /// proxy is unavailable.
  ///
  /// Only supported for [CloudApiType.claude]. Returns [ValidationFailure]
  /// when configured for OpenAI.
  Future<Result<Map<String, dynamic>>> sendMessages(
    Map<String, dynamic> body,
  ) async {
    if (apiType != CloudApiType.claude) {
      return const Err(
        ValidationFailure('sendMessages requires Claude-configured provider'),
      );
    }
    if (apiKey.isEmpty) {
      return const Err(ValidationFailure('No Anthropic API key configured'));
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _claudeUrl,
        data: body,
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final data = response.data;
      if (data == null) {
        return const Err(NetworkFailure('Empty response from Anthropic'));
      }
      return Success(data);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 429) return const Err(QuotaExceededFailure());
      if (code == 401) return const Err(UnauthenticatedFailure());
      return Err(NetworkFailure('Anthropic messages failed: ${e.message}'));
    }
  }

  /// Streams an Anthropic Messages response as SSE text deltas.
  /// Yields individual text chunks as they arrive; completes when the
  /// stream closes.
  Stream<String> streamMessages(Map<String, dynamic> body) async* {
    if (apiType != CloudApiType.claude) {
      throw StateError('streamMessages requires Claude-configured provider');
    }
    if (apiKey.isEmpty) {
      throw StateError('No Anthropic API key configured');
    }
    final streamBody = {...body, 'stream': true};
    final response = await _dio.post<ResponseBody>(
      _claudeUrl,
      data: streamBody,
      options: Options(
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        },
        responseType: ResponseType.stream,
      ),
    );

    final stream = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      try {
        final evt = jsonDecode(payload) as Map<String, dynamic>;
        if (evt['type'] == 'content_block_delta') {
          final delta = evt['delta'] as Map<String, dynamic>?;
          if (delta != null && delta['type'] == 'text_delta') {
            final text = delta['text'] as String? ?? '';
            if (text.isNotEmpty) yield text;
          }
        }
      } catch (_) {
        // Ignore malformed events; SSE streams sometimes contain heartbeats
        // or comment lines that we don't need.
      }
    }
  }
}

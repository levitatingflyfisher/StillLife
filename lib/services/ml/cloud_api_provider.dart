import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/image_media_type.dart';
import 'package:still_life/services/ml/multi_item_parser.dart';
import 'package:still_life/services/ml/single_item_parser.dart';
import 'package:still_life/services/ml/ollama_provider.dart'
    show AnalysisException;

/// Which cloud vision API to use.
enum CloudApiType {
  openai('OpenAI Vision'),
  claude('Claude Vision');

  final String label;
  const CloudApiType(this.label);
}

/// Tier 3: Cloud API provider supporting Claude Vision and any
/// OpenAI-compatible chat/completions endpoint (OpenAI itself, llamafile,
/// LM Studio, vLLM, ...) via a configurable base URL + model.
class CloudApiProvider extends AnalysisProvider {
  final Dio _dio;
  final String apiKey;
  final CloudApiType apiType;

  /// Base URL of the OpenAI-compatible endpoint (no trailing path).
  /// Only used when [apiType] is [CloudApiType.openai].
  final String openAiBaseUrl;

  /// Model name sent to the OpenAI-compatible endpoint.
  final String openAiModel;

  /// Minimum delay between successive API calls for rate limiting.
  final Duration rateLimitDelay;

  DateTime? _lastCallTime;

  static const String _claudeUrl = 'https://api.anthropic.com/v1/messages';

  String get _openaiUrl {
    final base = openAiBaseUrl.endsWith('/')
        ? openAiBaseUrl.substring(0, openAiBaseUrl.length - 1)
        : openAiBaseUrl;
    return '$base/chat/completions';
  }

  CloudApiProvider({
    required Dio dio,
    required this.apiKey,
    required this.apiType,
    this.openAiBaseUrl = 'https://api.openai.com/v1',
    this.openAiModel = 'gpt-4o',
    this.rateLimitDelay = const Duration(milliseconds: 500),
  }) : _dio = dio;

  @override
  String get name => apiType.label;

  @override
  AnalysisTier get tier => AnalysisTier.cloudApi;

  /// The stock OpenAI endpoint always requires a key; a differing base URL
  /// means the user pointed the tier at a self-hosted server, which may
  /// legitimately run keyless.
  static const String _officialOpenAiBaseUrl = 'https://api.openai.com/v1';

  bool get _isOfficialOpenAiEndpoint {
    final base = openAiBaseUrl.endsWith('/')
        ? openAiBaseUrl.substring(0, openAiBaseUrl.length - 1)
        : openAiBaseUrl;
    return base == _officialOpenAiBaseUrl;
  }

  /// Available when the configuration for the selected API type is
  /// complete — an incomplete config must never be probed with requests.
  ///
  /// The OpenAI-compatible tier deliberately allows an EMPTY key when the
  /// base URL points at a non-OpenAI server: the settings UI advertises
  /// "empty for local servers" (llamafile, LM Studio, vLLM) and the
  /// connection tester accepts that config, so the runtime cascade must
  /// agree. Keyless against the official endpoint stays unavailable —
  /// that is the unconfigured default and can never authenticate.
  @override
  Future<bool> isAvailable() async {
    return switch (apiType) {
      CloudApiType.claude => apiKey.isNotEmpty,
      CloudApiType.openai =>
        openAiBaseUrl.isNotEmpty &&
            openAiModel.isNotEmpty &&
            (apiKey.isNotEmpty || !_isOfficialOpenAiEndpoint),
    };
  }

  @override
  Future<AnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    Uint8List? contextFrame,
    String? existingLabel,
  }) async {
    await _enforceRateLimit();

    final prompt = existingLabel != null
        ? 'This item has been labeled "$existingLabel". $kSingleItemAnalysisPrompt'
        : kSingleItemAnalysisPrompt;

    return switch (apiType) {
      CloudApiType.openai => _analyzeWithOpenAI(imageBytes, prompt),
      CloudApiType.claude => _analyzeWithClaude(imageBytes, prompt),
    };
  }

  /// Analyzes a free-text prompt (no image). Claude goes through the
  /// Messages API; OpenAI through chat/completions.
  @override
  Future<AnalysisResult> analyzeText(
    String prompt, {
    AnalysisContext? context,
  }) async {
    await _enforceRateLimit();

    final label = context?.existingLabel;
    final fullPrompt = label != null
        ? 'This item has been labeled "$label". $prompt'
        : prompt;

    return switch (apiType) {
      CloudApiType.openai => _analyzeTextWithOpenAI(fullPrompt),
      CloudApiType.claude => _analyzeTextWithClaude(fullPrompt),
    };
  }

  /// Analyzes one shelf/room photo into 0..25 per-item results using the
  /// shared multi-item prompt. Both API shapes are supported; parsing is
  /// defensive (a wrapped `{"items": [...]}` object — what json_object
  /// mode forces — is tolerated, malformed entries are dropped).
  @override
  Future<List<AnalysisResult>> analyzeImageMulti(
    Uint8List imageBytes, {
    AnalysisContext? context,
  }) async {
    await _enforceRateLimit();

    final label = context?.existingLabel;
    final prompt = label != null
        ? 'This photo has been labeled "$label". $kMultiItemAnalysisPrompt'
        : kMultiItemAnalysisPrompt;
    // base64 of a multi-MB frame is a 50-200 ms synchronous stall — run
    // it off the UI isolate (the processing screen animates over these
    // calls in a loop).
    final imageBase64 = await compute(base64Encode, imageBytes);
    // Sniffed, not hardcoded: walkthrough frames are PNGs and Anthropic
    // rejects a declared-JPEG PNG with a 400.
    final mediaType = detectImageMediaType(imageBytes);

    final text = await switch (apiType) {
      CloudApiType.openai => _postOpenAiRaw([
        {'type': 'text', 'text': prompt},
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:$mediaType;base64,$imageBase64',
            'detail': 'high',
          },
        },
      ], maxTokens: kMultiItemMaxTokens),
      CloudApiType.claude => _postClaudeRaw([
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': mediaType,
            'data': imageBase64,
          },
        },
        {'type': 'text', 'text': prompt},
      ], maxTokens: kMultiItemMaxTokens),
    };

    return parseMultiItemResponse(text, defaultConfidence: 0.85);
  }

  /// Sends a raw text prompt and returns the model's reply verbatim — no
  /// item-analysis parsing applied. Rides the same raw-completion cores
  /// the other calls use.
  @override
  Future<String> completeText(String prompt, {int maxTokens = 1000}) async {
    await _enforceRateLimit();
    return switch (apiType) {
      CloudApiType.openai => _postOpenAiRaw(prompt, maxTokens: maxTokens),
      CloudApiType.claude => _postClaudeRaw(prompt, maxTokens: maxTokens),
    };
  }


  // ---------------------------------------------------------------------------
  // OpenAI Vision
  // ---------------------------------------------------------------------------

  Future<AnalysisResult> _analyzeWithOpenAI(
    Uint8List imageBytes,
    String prompt,
  ) async {
    final imageBase64 = await compute(base64Encode, imageBytes);
    final mediaType = detectImageMediaType(imageBytes);
    return _postOpenAi([
      {'type': 'text', 'text': prompt},
      {
        'type': 'image_url',
        'image_url': {
          'url': 'data:$mediaType;base64,$imageBase64',
          'detail': 'high',
        },
      },
    ]);
  }

  Future<AnalysisResult> _analyzeTextWithOpenAI(String prompt) {
    return _postOpenAi(prompt);
  }

  /// POSTs a single user message to the configured chat/completions
  /// endpoint and parses the reply as one item.
  Future<AnalysisResult> _postOpenAi(dynamic content) async =>
      _parseJsonResponse(await _postOpenAiRaw(content));

  /// POSTs a single user message ([content] is a plain string or a
  /// content-part list) to the configured chat/completions endpoint and
  /// returns the assistant's raw text.
  ///
  /// Requests compact JSON via `response_format: json_object` first; not
  /// every OpenAI-compatible server supports it, so a 400 triggers one
  /// retry relying on the prompt-engineered JSON instruction alone.
  Future<String> _postOpenAiRaw(dynamic content, {int maxTokens = 500}) async {
    Map<String, dynamic> buildBody({required bool jsonMode}) =>
        <String, dynamic>{
          'model': openAiModel,
          'messages': [
            {'role': 'user', 'content': content},
          ],
          'max_tokens': maxTokens,
          if (jsonMode) 'response_format': {'type': 'json_object'},
        };

    Future<String> post(Map<String, dynamic> body) async {
      final response = await _dio.post<Map<String, dynamic>>(
        _openaiUrl,
        data: body,
        options: Options(
          headers: {
            // Omitted for keyless local servers — mirrors the settings
            // screen's connection tester.
            if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return _extractOpenAiText(response.data);
    }

    try {
      return await post(buildBody(jsonMode: true));
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        try {
          return await post(buildBody(jsonMode: false));
        } on DioException catch (retryError) {
          throw AnalysisException(
            'OpenAI request failed: '
            '${retryError.message ?? retryError.type.name}',
          );
        }
      }
      throw AnalysisException(
        'OpenAI request failed: ${e.message ?? e.type.name}',
      );
    }
  }

  /// Pulls the assistant's raw text out of an OpenAI chat/completions
  /// envelope.
  String _extractOpenAiText(Map<String, dynamic>? data) {
    if (data == null) {
      throw const AnalysisException('Empty response from OpenAI');
    }

    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const AnalysisException('No choices in OpenAI response');
    }

    // Guarded, not cast: an OpenAI-compatible server may return
    // content: null (tool-call turn, content filter) or otherwise
    // malformed choices — those must surface as the typed
    // AnalysisException every caller's error contract handles, never a
    // raw TypeError.
    final choice = choices[0];
    final message = choice is Map<String, dynamic> ? choice['message'] : null;
    final content = message is Map<String, dynamic> ? message['content'] : null;
    if (content is! String) {
      throw const AnalysisException(
        'OpenAI response contained no text content',
      );
    }
    return content;
  }

  // ---------------------------------------------------------------------------
  // Claude Vision
  // ---------------------------------------------------------------------------

  Future<AnalysisResult> _analyzeWithClaude(
    Uint8List imageBytes,
    String prompt,
  ) async {
    final raw = await _postClaudeRaw([
      {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': detectImageMediaType(imageBytes),
          'data': await compute(base64Encode, imageBytes),
        },
      },
      {'type': 'text', 'text': prompt},
    ]);
    return _parseJsonResponse(raw);
  }

  Future<AnalysisResult> _analyzeTextWithClaude(String prompt) async =>
      _parseJsonResponse(await _postClaudeRaw(prompt));

  /// POSTs a single user message ([content] is a plain string or a
  /// content-block list) to the Anthropic Messages API and returns the
  /// first text block of the reply.
  Future<String> _postClaudeRaw(dynamic content, {int maxTokens = 500}) async {
    final requestBody = <String, dynamic>{
      'model': kDefaultClaudeAnalysisModel,
      'max_tokens': maxTokens,
      'messages': [
        {'role': 'user', 'content': content},
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

      return _extractClaudeText(response.data);
    } on DioException catch (e) {
      throw AnalysisException(
        'Claude request failed: ${e.message ?? e.type.name}',
      );
    }
  }

  /// Pulls the first text block's raw text out of an Anthropic Messages
  /// envelope.
  String _extractClaudeText(Map<String, dynamic>? data) {
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

    return textBlock['text'] as String;
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

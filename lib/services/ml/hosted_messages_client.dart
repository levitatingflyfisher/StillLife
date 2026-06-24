import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';

/// Stub client for the hosted-LLM `/v1/messages` pass-through endpoint.
///
/// Phase 22a ships the non-streaming path only. Streaming (SSE) lands
/// in Phase 23 once the server-side Anthropic bridge is stable. The
/// [send] method returns the raw JSON response so callers can decode
/// it into whatever Anthropic Messages shape they need.
class HostedMessagesClient {
  final Dio _dio;
  final String baseUrl;
  final Future<String> Function() apiKeyProvider;

  HostedMessagesClient({
    required Dio dio,
    required this.baseUrl,
    required this.apiKeyProvider,
  }) : _dio = dio;

  /// POSTs `body` to `/v1/messages`. Maps 401 → [UnauthenticatedFailure],
  /// 429 → [QuotaExceededFailure], everything else → [NetworkFailure].
  Future<Result<Map<String, dynamic>>> send(Map<String, dynamic> body) async {
    try {
      final bearer = await apiKeyProvider();
      final r = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/v1/messages',
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Content-Type': 'application/json',
          },
        ),
      );
      return Success(r.data!);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 429) return const Err(QuotaExceededFailure());
      if (code == 401) return const Err(UnauthenticatedFailure());
      return Err(NetworkFailure('messages: ${e.message}'));
    }
  }

  /// Streams SSE text deltas from `/v1/messages` with `stream: true`.
  /// Yields raw text chunks as the model produces them.
  Stream<String> sendStream(Map<String, dynamic> body) async* {
    final bearer = await apiKeyProvider();
    final streamBody = {...body, 'stream': true};
    final response = await _dio.post<ResponseBody>(
      '$baseUrl/v1/messages',
      data: streamBody,
      options: Options(
        headers: {
          'Authorization': 'Bearer $bearer',
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
        // Malformed / heartbeat lines are safely ignored.
      }
    }
  }
}

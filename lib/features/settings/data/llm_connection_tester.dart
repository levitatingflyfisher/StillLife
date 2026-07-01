import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/ml/cloud_api_provider.dart' show CloudApiType;

/// Outcome of a settings-screen connectivity probe. [message] is meant
/// to be shown to the user verbatim — it carries the *actual* result
/// (models found, HTTP status, transport error), never a canned excuse.
class ConnectionTestResult {
  final bool ok;
  final String message;
  final List<String> models;

  const ConnectionTestResult({
    required this.ok,
    required this.message,
    this.models = const [],
  });
}

/// Injectable Dio so widget tests can drive both outcomes without HTTP.
final llmConnectionTesterProvider = Provider<LlmConnectionTester>(
  (ref) => LlmConnectionTester(dio: Dio()),
);

/// Real connectivity probes behind the settings screen's "Test
/// Connection" buttons: Ollama via `GET /api/tags`, the cloud tier via
/// each vendor's cheap model-listing endpoint.
class LlmConnectionTester {
  final Dio _dio;

  static const Duration _timeout = Duration(seconds: 8);
  static const String _anthropicModelsUrl = 'https://api.anthropic.com/v1/models';

  LlmConnectionTester({required Dio dio}) : _dio = dio;

  /// Probes a local Ollama server: success = reachable, and the message
  /// reports which models are installed.
  Future<ConnectionTestResult> testOllama({
    required String host,
    required int port,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        'http://$host:$port/api/tags',
        options: Options(
          // connectTimeout too: send/receive timeouts never engage when
          // the TCP connect itself hangs (unroutable LAN IP), which
          // otherwise spins for the OS TCP timeout — minutes on Android.
          connectTimeout: _timeout,
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
      final models = _extractModelNames(response.data);
      if (models.isEmpty) {
        return const ConnectionTestResult(
          ok: true,
          message:
              'Connected — no models installed yet (run: ollama pull llava)',
        );
      }
      final shown = models.take(3).join(', ');
      final suffix = models.length > 3 ? ', …' : '';
      return ConnectionTestResult(
        ok: true,
        models: models,
        message:
            'Connected — ${models.length} '
            '${models.length == 1 ? 'model' : 'models'}: $shown$suffix',
      );
    } on DioException catch (e) {
      return ConnectionTestResult(
        ok: false,
        message: 'Ollama unreachable: ${_describe(e)}',
      );
    } catch (e) {
      return ConnectionTestResult(ok: false, message: 'Ollama check failed: $e');
    }
  }

  /// Probes the BYO cloud tier with a cheap real call for the selected
  /// type: Anthropic `GET /v1/models` (x-api-key), OpenAI-compatible
  /// `GET {base}/models` (bearer; omitted for keyless local servers).
  Future<ConnectionTestResult> testCloud({
    required CloudApiType apiType,
    required String apiKey,
    String openAiBaseUrl = '',
  }) async {
    try {
      switch (apiType) {
        case CloudApiType.claude:
          if (apiKey.isEmpty) {
            return const ConnectionTestResult(
              ok: false,
              message: 'Enter a Claude API key first',
            );
          }
          await _dio.get<dynamic>(
            _anthropicModelsUrl,
            options: Options(
              headers: {
                'x-api-key': apiKey,
                'anthropic-version': '2023-06-01',
              },
              connectTimeout: _timeout,
              sendTimeout: _timeout,
              receiveTimeout: _timeout,
            ),
          );
          return const ConnectionTestResult(
            ok: true,
            message: 'Connected — Anthropic accepted the API key',
          );
        case CloudApiType.openai:
          if (openAiBaseUrl.isEmpty) {
            return const ConnectionTestResult(
              ok: false,
              message: 'Enter a base URL first',
            );
          }
          final base = openAiBaseUrl.endsWith('/')
              ? openAiBaseUrl.substring(0, openAiBaseUrl.length - 1)
              : openAiBaseUrl;
          await _dio.get<dynamic>(
            '$base/models',
            options: Options(
              headers: {
                if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
              },
              connectTimeout: _timeout,
              sendTimeout: _timeout,
              receiveTimeout: _timeout,
            ),
          );
          return ConnectionTestResult(
            ok: true,
            message: 'Connected — $base/models responded',
          );
      }
    } on DioException catch (e) {
      return ConnectionTestResult(
        ok: false,
        message: 'Connection failed: ${_describe(e)}',
      );
    } catch (e) {
      return ConnectionTestResult(ok: false, message: 'Connection failed: $e');
    }
  }

  /// Pulls the model names out of an Ollama `/api/tags` body, tolerating
  /// any malformed shape — reachability is the success criterion.
  List<String> _extractModelNames(dynamic data) {
    final names = <String>[];
    try {
      if (data is Map) {
        final list = data['models'];
        if (list is List) {
          for (final entry in list) {
            if (entry is Map && entry['name'] is String) {
              names.add(entry['name'] as String);
            }
          }
        }
      }
    } catch (_) {
      // Malformed body — treat as zero models, never crash.
    }
    return names;
  }

  /// Renders a DioException as the actual failure the user needs to see:
  /// HTTP status + server-provided detail when present, otherwise the
  /// transport error (falling back to the wrapped inner error — some
  /// adapters leave `message` null).
  String _describe(DioException e) {
    final code = e.response?.statusCode;
    if (code != null) {
      final detail = _errorDetail(e.response?.data);
      return detail == null ? 'HTTP $code' : 'HTTP $code — $detail';
    }
    if (e.message != null && e.message!.isNotEmpty) return e.message!;
    if (e.error != null) return e.error.toString();
    return e.type.name;
  }

  /// Extracts a human-readable error message from common error-body
  /// shapes ({"error": {"message": ...}} or {"error": "..."}), guarding
  /// against anything malformed.
  String? _errorDetail(dynamic data) {
    try {
      if (data is Map) {
        final error = data['error'];
        if (error is Map && error['message'] is String) {
          return error['message'] as String;
        }
        if (error is String) return error;
      }
    } catch (_) {
      // Unparseable error body — the status code alone will have to do.
    }
    return null;
  }
}

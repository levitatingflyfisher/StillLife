import 'package:dio/dio.dart';

import 'ollama_host.dart';

/// Web stub: browsers cannot speak mDNS, so automatic Ollama discovery is
/// native-only. Probing an explicitly typed host still works over HTTP.
class OllamaDiscovery {
  final Dio _dio;

  static const int defaultPort = 11434;

  OllamaDiscovery({required Dio dio}) : _dio = dio;

  Stream<OllamaHost> discoverOllamaInstances({
    Duration timeout = const Duration(seconds: 10),
  }) =>
      const Stream<OllamaHost>.empty();

  Future<bool> testConnection(String host, int port) async {
    try {
      final response = await _dio.get<dynamic>(
        'http://$host:$port/api/tags',
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

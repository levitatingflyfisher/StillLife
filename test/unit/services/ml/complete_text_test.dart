import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:still_life/services/ml/cloud_api_provider.dart';
import 'package:still_life/services/ml/hosted_provider.dart';
import 'package:still_life/services/ml/ollama_provider.dart';
import 'package:still_life/services/ml/on_device_provider.dart';

/// Every tier exposes `completeText` — the raw-completion seam: send a
/// text prompt, get the model's raw reply back with NO item-analysis
/// parsing applied. The receipt-structuring stage rides this seam; its
/// reply shape is a receipt, not an AnalysisResult.
void main() {
  late Dio dio;
  late DioAdapter adapter;
  late List<RequestOptions> captured;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    captured = [];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured.add(options);
          handler.next(options);
        },
      ),
    );
  });

  group('OllamaProvider.completeText', () {
    test('posts the prompt with no image and returns the raw reply', () async {
      adapter.onPost(
        'http://localhost:11434/api/generate',
        (s) => s.reply(200, {'response': '{"storeName":"Kroger"}'}),
        data: Matchers.any,
      );

      final provider = OllamaProvider(dio: dio);
      final raw = await provider.completeText('structure this receipt');

      expect(raw, '{"storeName":"Kroger"}');
      final body = captured.single.data as Map<String, dynamic>;
      expect(body['prompt'], 'structure this receipt');
      expect(body.containsKey('images'), isFalse,
          reason: 'raw completion is text-only');
    });

    test('wraps transport errors in AnalysisException', () async {
      adapter.onPost(
        'http://localhost:11434/api/generate',
        (s) => s.reply(500, {'error': 'boom'}),
        data: Matchers.any,
      );

      await expectLater(
        () => OllamaProvider(dio: dio).completeText('p'),
        throwsA(isA<AnalysisException>()),
      );
    });
  });

  group('CloudApiProvider.completeText', () {
    test('Claude: returns the first text block verbatim', () async {
      adapter.onPost(
        'https://api.anthropic.com/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {'type': 'text', 'text': 'raw claude reply'},
          ],
        }),
        data: Matchers.any,
      );

      final provider = CloudApiProvider(
        dio: dio,
        apiKey: 'k',
        apiType: CloudApiType.claude,
        rateLimitDelay: Duration.zero,
      );
      expect(await provider.completeText('p'), 'raw claude reply');
    });

    test('OpenAI-compatible: returns the assistant content verbatim',
        () async {
      adapter.onPost(
        'https://api.openai.com/v1/chat/completions',
        (s) => s.reply(200, {
          'choices': [
            {
              'message': {'content': 'raw openai reply'},
            },
          ],
        }),
        data: Matchers.any,
      );

      final provider = CloudApiProvider(
        dio: dio,
        apiKey: 'k',
        apiType: CloudApiType.openai,
        rateLimitDelay: Duration.zero,
      );
      expect(await provider.completeText('p'), 'raw openai reply');
    });
  });

  group('HostedProvider.completeText', () {
    test('rides the /v1/messages passthrough and returns the text', () async {
      adapter.onPost(
        'https://w.test/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {'type': 'text', 'text': 'raw hosted reply'},
          ],
        }),
        data: Matchers.any,
      );

      final provider = HostedProvider(
        dio: dio,
        baseUrl: 'https://w.test',
        apiKeyProvider: () async => 'sl_live_ok',
        maxRetries: 1,
      );
      expect(await provider.completeText('p'), 'raw hosted reply');
      expect(captured.single.headers['Authorization'], 'Bearer sl_live_ok');
    });
  });

  group('OnDeviceProvider.completeText', () {
    test('throws — no on-device text model exists', () {
      expect(
        () => OnDeviceProvider().completeText('p'),
        throwsStateError,
      );
    });
  });
}

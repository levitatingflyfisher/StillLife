import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:still_life/features/settings/data/llm_connection_tester.dart';
import 'package:still_life/services/ml/cloud_api_provider.dart'
    show CloudApiType;

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

  LlmConnectionTester make() => LlmConnectionTester(dio: dio);

  group('testOllama', () {
    test('GETs /api/tags and reports the models found', () async {
      adapter.onGet(
        'http://o.test:11434/api/tags',
        (s) => s.reply(200, {
          'models': [
            {'name': 'llava:latest'},
            {'name': 'qwen2.5vl:7b'},
          ],
        }),
      );

      final r = await make().testOllama(host: 'o.test', port: 11434);

      expect(r.ok, isTrue);
      expect(r.models, ['llava:latest', 'qwen2.5vl:7b']);
      expect(r.message, contains('llava:latest'));
      expect(captured.single.path, 'http://o.test:11434/api/tags');
      expect(captured.single.connectTimeout, isNotNull,
          reason: 'send/receive timeouts never fire when the TCP connect '
              'itself hangs — an unroutable LAN IP must not spin the '
              'Test Connection button for the OS TCP timeout (minutes)');
    });

    test('reachable server with zero models is still a success, with an '
        'actionable message', () async {
      adapter.onGet(
        'http://o.test:11434/api/tags',
        (s) => s.reply(200, {'models': <dynamic>[]}),
      );

      final r = await make().testOllama(host: 'o.test', port: 11434);

      expect(r.ok, isTrue);
      expect(r.models, isEmpty);
      expect(r.message.toLowerCase(), contains('no models'));
    });

    test('unreachable server surfaces the actual error, not a canned '
        'excuse', () async {
      adapter.onGet(
        'http://o.test:11434/api/tags',
        (s) => s.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: 'http://o.test:11434'),
            type: DioExceptionType.connectionError,
            error: 'connection refused',
          ),
        ),
      );

      final r = await make().testOllama(host: 'o.test', port: 11434);

      expect(r.ok, isFalse);
      expect(r.message, contains('connection refused'));
    });

    test('malformed body is tolerated — reachability still wins', () async {
      adapter.onGet(
        'http://o.test:11434/api/tags',
        (s) => s.reply(200, 'not json at all'),
      );

      final r = await make().testOllama(host: 'o.test', port: 11434);

      expect(r.ok, isTrue);
      expect(r.models, isEmpty);
    });
  });

  group('testCloud — Anthropic', () {
    test('GETs /v1/models with the x-api-key header', () async {
      adapter.onGet(
        'https://api.anthropic.com/v1/models',
        (s) => s.reply(200, {
          'data': [
            {'id': 'claude-sonnet-4-20250514'},
          ],
        }),
      );

      final r = await make().testCloud(
        apiType: CloudApiType.claude,
        apiKey: 'sk-ant-test',
      );

      expect(r.ok, isTrue);
      expect(captured.single.headers['x-api-key'], 'sk-ant-test');
      expect(captured.single.connectTimeout, isNotNull);
      expect(captured.single.headers['anthropic-version'], isNotNull);
    });

    test('401 shows the actual HTTP failure', () async {
      adapter.onGet(
        'https://api.anthropic.com/v1/models',
        (s) => s.reply(401, {
          'error': {'type': 'authentication_error', 'message': 'invalid key'},
        }),
      );

      final r = await make().testCloud(
        apiType: CloudApiType.claude,
        apiKey: 'sk-ant-bad',
      );

      expect(r.ok, isFalse);
      expect(r.message, contains('401'));
      expect(r.message, contains('invalid key'));
    });

    test('refuses without HTTP when no key is entered', () async {
      final r = await make().testCloud(
        apiType: CloudApiType.claude,
        apiKey: '',
      );

      expect(r.ok, isFalse);
      expect(r.message.toLowerCase(), contains('key'));
      expect(captured, isEmpty, reason: 'no key means no request');
    });
  });

  group('testCloud — OpenAI-compatible', () {
    test('GETs {base}/models with a bearer', () async {
      adapter.onGet(
        'http://localhost:8080/v1/models',
        (s) => s.reply(200, {
          'data': [
            {'id': 'LLaMA_CPP'},
          ],
        }),
      );

      final r = await make().testCloud(
        apiType: CloudApiType.openai,
        apiKey: 'sk-compat',
        openAiBaseUrl: 'http://localhost:8080/v1/',
      );

      expect(r.ok, isTrue);
      expect(captured.single.path, 'http://localhost:8080/v1/models');
      expect(captured.single.connectTimeout, isNotNull);
      expect(captured.single.headers['Authorization'], 'Bearer sk-compat');
    });

    test('keyless local servers are probed without an Authorization '
        'header', () async {
      adapter.onGet(
        'http://localhost:8080/v1/models',
        (s) => s.reply(200, {'data': <dynamic>[]}),
      );

      final r = await make().testCloud(
        apiType: CloudApiType.openai,
        apiKey: '',
        openAiBaseUrl: 'http://localhost:8080/v1',
      );

      expect(r.ok, isTrue);
      expect(captured.single.headers.containsKey('Authorization'), isFalse);
    });

    test('HTTP failure surfaces status and detail', () async {
      adapter.onGet(
        'http://localhost:8080/v1/models',
        (s) => s.reply(500, {'error': 'server exploded'}),
      );

      final r = await make().testCloud(
        apiType: CloudApiType.openai,
        apiKey: 'k',
        openAiBaseUrl: 'http://localhost:8080/v1',
      );

      expect(r.ok, isFalse);
      expect(r.message, contains('500'));
      expect(r.message, contains('server exploded'));
    });
  });
}

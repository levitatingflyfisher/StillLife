import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:still_life/services/ml/analysis_provider.dart'
    show kDefaultClaudeAnalysisModel;
import 'package:still_life/services/ml/cloud_api_provider.dart';
import 'package:still_life/services/ml/multi_item_parser.dart'
    show kMultiItemMaxTokens;
import 'package:still_life/services/ml/ollama_provider.dart'
    show AnalysisException;

/// Replays canned responses in sequence and records every request —
/// lets a test assert on a retry (same route hit twice).
class _SequencedAdapter implements HttpClientAdapter {
  final List<ResponseBody Function(RequestOptions)> handlers;
  final List<RequestOptions> requests = [];
  int _next = 0;

  _SequencedAdapter(this.handlers);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handlers[_next++](options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(int status, Map<String, dynamic> json) =>
    ResponseBody.fromString(
      jsonEncode(json),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

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

  CloudApiProvider make(CloudApiType type) => CloudApiProvider(
    dio: dio,
    apiKey: type == CloudApiType.claude ? 'sk-ant-test' : 'sk-test',
    apiType: type,
    rateLimitDelay: Duration.zero,
  );

  group('CloudApiProvider.analyzeText — Claude', () {
    test('posts a text-only Messages body and parses the JSON reply', () async {
      adapter.onPost(
        'https://api.anthropic.com/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {
              'type': 'text',
              'text':
                  '{"name":"Vitamix 5200","category":"Kitchenware",'
                  '"estimatedRetailPrice":499.99,"description":"blender"}',
            },
          ],
        }),
        data: Matchers.any,
      );

      final r = await make(CloudApiType.claude).analyzeText('terse prompt');

      expect(r.itemName, 'Vitamix 5200');
      expect(r.category, 'Kitchenware');
      expect(r.estimatedPrice, 499.99);

      final body = captured.single.data as Map<String, dynamic>;
      expect(
        jsonEncode(body['messages']),
        isNot(contains('image')),
        reason: 'text analysis must not attach an image block',
      );
      expect(jsonEncode(body['messages']), contains('terse prompt'));
      expect(
        body['model'],
        kDefaultClaudeAnalysisModel,
        reason: 'the BYO Claude tier must ride the current shared model '
            'alias, never a dated deprecated snapshot',
      );
    });

    test('malformed model JSON falls back gracefully, no crash', () async {
      adapter.onPost(
        'https://api.anthropic.com/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {'type': 'text', 'text': 'Sure! It looks like a nice blender.'},
          ],
        }),
        data: Matchers.any,
      );

      final r = await make(CloudApiType.claude).analyzeText('terse prompt');
      expect(r.confidence, lessThan(0.5));
    });
  });

  group('CloudApiProvider.analyzeText — OpenAI', () {
    test('posts a text-only chat/completions body and parses the reply', () async {
      adapter.onPost(
        'https://api.openai.com/v1/chat/completions',
        (s) => s.reply(200, {
          'choices': [
            {
              'message': {
                'content':
                    '{"name":"Desk Lamp","category":"Decor",'
                    '"estimatedRetailPrice":35,"description":"lamp"}',
              },
            },
          ],
        }),
        data: Matchers.any,
      );

      final r = await make(CloudApiType.openai).analyzeText('terse prompt');

      expect(r.itemName, 'Desk Lamp');
      expect(r.estimatedPrice, 35);

      final body = captured.single.data as Map<String, dynamic>;
      expect(
        jsonEncode(body['messages']),
        isNot(contains('image_url')),
        reason: 'text analysis must not attach an image part',
      );
    });
  });

  group('CloudApiProvider — OpenAI-compatible endpoint config', () {
    CloudApiProvider makeCompat() => CloudApiProvider(
      dio: dio,
      apiKey: 'sk-local',
      apiType: CloudApiType.openai,
      openAiBaseUrl: 'http://llamafile.test:8080/v1',
      openAiModel: 'qwen2.5-7b',
      rateLimitDelay: Duration.zero,
    );

    test('analyzeText targets the configured base URL and model', () async {
      adapter.onPost(
        'http://llamafile.test:8080/v1/chat/completions',
        (s) => s.reply(200, {
          'choices': [
            {
              'message': {'content': '{"name":"Rake","category":"Tools"}'},
            },
          ],
        }),
        data: Matchers.any,
      );

      final r = await makeCompat().analyzeText('terse prompt');
      expect(r.itemName, 'Rake');

      final body = captured.single.data as Map<String, dynamic>;
      expect(body['model'], 'qwen2.5-7b');
    });

    test('analyzeImage sends an image_url data URI and requests compact '
        'JSON via response_format', () async {
      adapter.onPost(
        'http://llamafile.test:8080/v1/chat/completions',
        (s) => s.reply(200, {
          'choices': [
            {
              'message': {'content': '{"name":"Lamp","category":"Decor"}'},
            },
          ],
        }),
        data: Matchers.any,
      );

      final r = await makeCompat().analyzeImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(r.itemName, 'Lamp');

      final body = captured.single.data as Map<String, dynamic>;
      expect(jsonEncode(body['messages']), contains('data:image/jpeg;base64'));
      expect(body['response_format'], {'type': 'json_object'});
    });

    test('falls back to prompt-engineered JSON when the server rejects '
        'response_format with 400', () async {
      final sequenced = _SequencedAdapter([
        (_) => _jsonBody(400, {
          'error': {'message': "unknown field 'response_format'"},
        }),
        (_) => _jsonBody(200, {
          'choices': [
            {
              'message': {'content': '{"name":"Rake","category":"Tools"}'},
            },
          ],
        }),
      ]);
      final seqDio = Dio()..httpClientAdapter = sequenced;
      final p = CloudApiProvider(
        dio: seqDio,
        apiKey: 'sk-local',
        apiType: CloudApiType.openai,
        openAiBaseUrl: 'http://llamafile.test:8080/v1',
        openAiModel: 'qwen2.5-7b',
        rateLimitDelay: Duration.zero,
      );

      final r = await p.analyzeText('terse prompt');
      expect(r.itemName, 'Rake');

      expect(sequenced.requests, hasLength(2));
      final first = sequenced.requests[0].data as Map<String, dynamic>;
      final second = sequenced.requests[1].data as Map<String, dynamic>;
      expect(first.containsKey('response_format'), isTrue);
      expect(second.containsKey('response_format'), isFalse);
    });
  });

  group('CloudApiProvider.analyzeImageMulti — Claude', () {
    test('posts the shelf photo as an image block with the multi-item '
        'prompt and parses the array', () async {
      adapter.onPost(
        'https://api.anthropic.com/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {
              'type': 'text',
              'text':
                  '[{"name":"Blender","brand":"Vitamix","category":'
                  '"Kitchenware","estimatedRetailPrice":499.99,'
                  '"confidence":0.95},'
                  '{"name":"Cookbook","category":"Books","confidence":0.5}]',
            },
          ],
        }),
        data: Matchers.any,
      );

      final results = await make(CloudApiType.claude).analyzeImageMulti(
        Uint8List.fromList([1, 2, 3]),
      );

      expect(results, hasLength(2));
      expect(results[0].itemName, 'Blender');
      expect(results[0].brand, 'Vitamix');
      expect(results[0].confidence, 0.95);
      expect(results[1].itemName, 'Cookbook');

      final body = captured.single.data as Map<String, dynamic>;
      final encoded = jsonEncode(body['messages']);
      expect(encoded, contains('"type":"image"'),
          reason: 'the shelf photo must ride along as an image block');
      expect(encoded.toLowerCase(), contains('each distinct'));
      expect(body['max_tokens'], kMultiItemMaxTokens,
          reason: 'a full-cap reply must fit the output budget — '
              'truncation loses the whole array');
    });

    test('malformed model output yields an empty list, never a crash',
        () async {
      adapter.onPost(
        'https://api.anthropic.com/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {'type': 'text', 'text': 'I see many nice things on the shelf!'},
          ],
        }),
        data: Matchers.any,
      );

      final results =
          await make(CloudApiType.claude).analyzeImageMulti(Uint8List(1));
      expect(results, isEmpty);
    });
  });

  group('CloudApiProvider.analyzeImageMulti — OpenAI-compatible', () {
    test('posts an image_url part and tolerates the wrapped {"items":[...]} '
        'shape that json_object mode forces', () async {
      adapter.onPost(
        'https://api.openai.com/v1/chat/completions',
        (s) => s.reply(200, {
          'choices': [
            {
              'message': {
                'content':
                    '{"items":[{"name":"Rake","category":"Tools",'
                    '"confidence":0.8}]}',
              },
            },
          ],
        }),
        data: Matchers.any,
      );

      final results = await make(CloudApiType.openai).analyzeImageMulti(
        Uint8List.fromList([1, 2, 3]),
      );

      expect(results, hasLength(1));
      expect(results.single.itemName, 'Rake');
      expect(results.single.confidence, 0.8);

      final body = captured.single.data as Map<String, dynamic>;
      expect(jsonEncode(body['messages']), contains('data:image/jpeg;base64'));
      expect(
        jsonEncode(body['messages']).toLowerCase(),
        contains('each distinct'),
      );
      expect(body['max_tokens'], kMultiItemMaxTokens,
          reason: 'a full-cap reply must fit the output budget — '
              'truncation loses the whole array');
    });
  });

  group('CloudApiProvider — declared media type matches the bytes', () {
    final pngBytes = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      1, 2, 3,
    ]);

    test('Claude analyzeImageMulti declares image/png for PNG frames — '
        'Anthropic 400s on a media_type/bytes mismatch', () async {
      adapter.onPost(
        'https://api.anthropic.com/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {'type': 'text', 'text': '[]'},
          ],
        }),
        data: Matchers.any,
      );

      await make(CloudApiType.claude).analyzeImageMulti(pngBytes);

      final body = captured.single.data as Map<String, dynamic>;
      expect(jsonEncode(body['messages']), contains('"image/png"'));
      expect(jsonEncode(body['messages']), isNot(contains('image/jpeg')));
    });

    test('Claude analyzeImage declares image/png for PNG bytes too',
        () async {
      adapter.onPost(
        'https://api.anthropic.com/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {'type': 'text', 'text': '{"name":"Chair"}'},
          ],
        }),
        data: Matchers.any,
      );

      await make(CloudApiType.claude).analyzeImage(imageBytes: pngBytes);

      final body = captured.single.data as Map<String, dynamic>;
      expect(jsonEncode(body['messages']), contains('"image/png"'));
    });

    test('OpenAI data URI carries the sniffed media type', () async {
      adapter.onPost(
        'https://api.openai.com/v1/chat/completions',
        (s) => s.reply(200, {
          'choices': [
            {
              'message': {'content': '{"items":[]}'},
            },
          ],
        }),
        data: Matchers.any,
      );

      await make(CloudApiType.openai).analyzeImageMulti(pngBytes);

      final body = captured.single.data as Map<String, dynamic>;
      expect(jsonEncode(body['messages']), contains('data:image/png;base64'));
    });
  });

  group('CloudApiProvider — off-main-isolate encode (characterization)', () {
    test('a multi-hundred-KB frame round-trips through the isolate encode '
        'byte-identically', () async {
      adapter.onPost(
        'https://api.anthropic.com/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {'type': 'text', 'text': '[]'},
          ],
        }),
        data: Matchers.any,
      );

      final big = Uint8List.fromList(
        List<int>.generate(300 * 1024, (i) => i % 251),
      );
      await make(CloudApiType.claude).analyzeImageMulti(big);

      final body = captured.single.data as Map<String, dynamic>;
      final content =
          ((body['messages'] as List).first as Map)['content'] as List;
      final image = (content.first as Map)['source'] as Map;
      expect(image['data'], base64Encode(big),
          reason: 'offloading the encode must not change the payload');
    });
  });

  group('CloudApiProvider — malformed OpenAI envelopes', () {
    test('content: null (tool-call turn / content filter) throws the typed '
        'AnalysisException, not a raw TypeError', () async {
      adapter.onPost(
        'https://api.openai.com/v1/chat/completions',
        (s) => s.reply(200, {
          'choices': [
            {
              'message': {'content': null},
            },
          ],
        }),
        data: Matchers.any,
      );

      await expectLater(
        make(CloudApiType.openai).completeText('prompt'),
        throwsA(
          isA<AnalysisException>().having(
            (e) => e.message,
            'message',
            contains('no text'),
          ),
        ),
      );
    });

    test('non-map choice entries throw the typed AnalysisException too',
        () async {
      adapter.onPost(
        'https://api.openai.com/v1/chat/completions',
        (s) => s.reply(200, {
          'choices': ['garbage'],
        }),
        data: Matchers.any,
      );

      await expectLater(
        make(CloudApiType.openai).completeText('prompt'),
        throwsA(isA<AnalysisException>()),
      );
    });
  });

  group('CloudApiProvider.isAvailable — selected config completeness', () {
    test('claude: available iff the API key is set', () async {
      final withKey = CloudApiProvider(
        dio: dio,
        apiKey: 'sk-ant-x',
        apiType: CloudApiType.claude,
      );
      final withoutKey = CloudApiProvider(
        dio: dio,
        apiKey: '',
        apiType: CloudApiType.claude,
      );
      expect(await withKey.isAvailable(), isTrue);
      expect(await withoutKey.isAvailable(), isFalse);
    });

    test('openai: unavailable when base URL or model is blanked', () async {
      final noBase = CloudApiProvider(
        dio: dio,
        apiKey: 'sk-x',
        apiType: CloudApiType.openai,
        openAiBaseUrl: '',
      );
      final noModel = CloudApiProvider(
        dio: dio,
        apiKey: 'sk-x',
        apiType: CloudApiType.openai,
        openAiModel: '',
      );
      final complete = CloudApiProvider(
        dio: dio,
        apiKey: 'sk-x',
        apiType: CloudApiType.openai,
      );
      expect(await noBase.isAvailable(), isFalse);
      expect(await noModel.isAvailable(), isFalse);
      expect(
        await complete.isAvailable(),
        isTrue,
        reason: 'defaults (api.openai.com + gpt-4o) complete the config',
      );
    });

    test('openai: a keyless LOCAL server is available — the settings UI '
        'advertises "empty for local servers"', () async {
      final keylessLocal = CloudApiProvider(
        dio: dio,
        apiKey: '',
        apiType: CloudApiType.openai,
        openAiBaseUrl: 'http://localhost:8080/v1',
      );
      expect(
        await keylessLocal.isAvailable(),
        isTrue,
        reason: 'llamafile/LM Studio/vLLM run keyless; Test Connection '
            'accepts this config, so the runtime cascade must too',
      );
    });

    test('openai: keyless against the DEFAULT OpenAI endpoint stays '
        'unavailable (unconfigured build must report NoAiConfigured)',
        () async {
      final keylessDefault = CloudApiProvider(
        dio: dio,
        apiKey: '',
        apiType: CloudApiType.openai,
      );
      final keylessDefaultSlash = CloudApiProvider(
        dio: dio,
        apiKey: '',
        apiType: CloudApiType.openai,
        openAiBaseUrl: 'https://api.openai.com/v1/',
      );
      expect(await keylessDefault.isAvailable(), isFalse);
      expect(await keylessDefaultSlash.isAvailable(), isFalse);
    });
  });
}

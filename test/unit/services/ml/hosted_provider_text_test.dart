import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:still_life/services/ml/analysis_provider.dart'
    show kDefaultClaudeAnalysisModel;
import 'package:still_life/services/ml/hosted_provider.dart';
import 'package:still_life/services/ml/multi_item_parser.dart'
    show kMultiItemMaxTokens;

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

  HostedProvider make() => HostedProvider(
    dio: dio,
    baseUrl: 'https://w.test',
    apiKeyProvider: () async => 'sl_live_ok',
    maxRetries: 1,
  );

  group('HostedProvider.analyzeText', () {
    test('posts an Anthropic Messages body through /v1/messages', () async {
      adapter.onPost(
        'https://w.test/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {
              'type': 'text',
              'text':
                  '{"name":"Garden Hose","category":"Tools",'
                  '"estimatedRetailPrice":25,"description":"50ft hose"}',
            },
          ],
        }),
        data: Matchers.any,
      );

      final r = await make().analyzeText('terse extraction prompt');

      expect(r.itemName, 'Garden Hose');
      expect(r.estimatedPrice, 25);

      final req = captured.single;
      expect(req.headers['Authorization'], 'Bearer sl_live_ok');
      final body = req.data as Map<String, dynamic>;
      expect(body['messages'], isA<List<dynamic>>());
      expect(body.toString(), contains('terse extraction prompt'));
      expect(body['model'], kDefaultClaudeAnalysisModel,
          reason: 'hosted passthrough bodies must not pin a deprecated '
              'dated model snapshot');
    });

    test('401 throws AuthRequiredException like analyzeImage does', () async {
      adapter.onPost(
        'https://w.test/v1/messages',
        (s) => s.reply(401, {'error': 'invalid_bearer'}),
        data: Matchers.any,
      );

      await expectLater(
        () => make().analyzeText('prompt'),
        throwsA(isA<AuthRequiredException>()),
      );
    });

    test('malformed model JSON falls back gracefully, no crash', () async {
      adapter.onPost(
        'https://w.test/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {'type': 'text', 'text': 'not json at all'},
          ],
        }),
        data: Matchers.any,
      );

      final r = await make().analyzeText('prompt');
      expect(r.confidence, lessThan(0.5));
    });
  });

  group('HostedProvider.analyzeImageMulti', () {
    test('passes the shelf photo through /v1/messages as an Anthropic '
        'image block and parses the array', () async {
      adapter.onPost(
        'https://w.test/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {
              'type': 'text',
              'text':
                  '[{"name":"Garden Hose","category":"Tools",'
                  '"confidence":0.7},'
                  '{"name":"Watering Can","category":"Tools",'
                  '"confidence":0.65}]',
            },
          ],
        }),
        data: Matchers.any,
      );

      final results = await make().analyzeImageMulti(
        Uint8List.fromList([1, 2, 3]),
      );

      expect(results, hasLength(2));
      expect(results[0].itemName, 'Garden Hose');
      expect(results[1].itemName, 'Watering Can');

      final req = captured.single;
      expect(req.headers['Authorization'], 'Bearer sl_live_ok');
      final encoded = jsonEncode((req.data as Map<String, dynamic>)['messages']);
      expect(encoded, contains('"type":"image"'),
          reason: 'the shelf photo must ride the messages passthrough');
      expect(encoded.toLowerCase(), contains('each distinct'));
      expect((req.data as Map<String, dynamic>)['max_tokens'],
          kMultiItemMaxTokens,
          reason: 'a full-cap reply must fit the output budget — '
              'truncation loses the whole array');
    });

    test('declares image/png for PNG frames — the walkthrough pipeline '
        'feeds ffmpeg PNGs, and Anthropic 400s on a mismatch', () async {
      adapter.onPost(
        'https://w.test/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {'type': 'text', 'text': '[]'},
          ],
        }),
        data: Matchers.any,
      );

      await make().analyzeImageMulti(
        Uint8List.fromList(
          [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2],
        ),
      );

      final encoded =
          jsonEncode((captured.single.data as Map<String, dynamic>)['messages']);
      expect(encoded, contains('"image/png"'));
      expect(encoded, isNot(contains('image/jpeg')));
    });

    test('401 throws AuthRequiredException like the other analyze calls',
        () async {
      adapter.onPost(
        'https://w.test/v1/messages',
        (s) => s.reply(401, {'error': 'invalid_bearer'}),
        data: Matchers.any,
      );

      await expectLater(
        () => make().analyzeImageMulti(Uint8List(1)),
        throwsA(isA<AuthRequiredException>()),
      );
    });

    test('malformed model output yields an empty list, never a crash',
        () async {
      adapter.onPost(
        'https://w.test/v1/messages',
        (s) => s.reply(200, {
          'content': [
            {'type': 'text', 'text': 'what a lovely shelf'},
          ],
        }),
        data: Matchers.any,
      );

      final results = await make().analyzeImageMulti(Uint8List(1));
      expect(results, isEmpty);
    });
  });
}

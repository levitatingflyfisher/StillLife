import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:still_life/services/ml/ollama_provider.dart';

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

  OllamaProvider make() =>
      OllamaProvider(dio: dio, baseUrl: 'http://o.test:11434', model: 'llava');

  group('OllamaProvider.analyzeText', () {
    test('posts the prompt to /api/generate with NO image attached', () async {
      adapter.onPost(
        'http://o.test:11434/api/generate',
        (s) => s.reply(200, {
          'response':
              '{"name":"Bosch Drill","category":"Tools",'
              '"estimatedRetailPrice":120,"description":"power tool"}',
        }),
        data: Matchers.any,
      );

      final r = await make().analyzeText(
        'Extract the item from: "Bosch drill paid 120 dollars"',
      );

      expect(r.itemName, 'Bosch Drill');
      expect(r.category, 'Tools');
      expect(r.estimatedPrice, 120);

      final body = captured.single.data as Map<String, dynamic>;
      expect(body['prompt'], contains('Bosch drill paid 120 dollars'));
      expect(
        body.containsKey('images'),
        isFalse,
        reason: 'text analysis must not smuggle a placeholder image',
      );
      expect(body['stream'], isFalse);
    });

    test('malformed model JSON falls back gracefully, no crash', () async {
      adapter.onPost(
        'http://o.test:11434/api/generate',
        (s) => s.reply(200, {'response': '{"name": totally broken json}'}),
        data: Matchers.any,
      );

      final r = await make().analyzeText('anything');
      // Fallback path: low confidence, raw text retained — never a throw.
      expect(r.confidence, lessThan(0.5));
      expect(r.rawResponse.containsKey('raw_text'), isTrue);
    });

    test('HTTP failure surfaces as typed AnalysisException', () async {
      adapter.onPost(
        'http://o.test:11434/api/generate',
        (s) => s.reply(500, {'error': 'boom'}),
        data: Matchers.any,
      );

      await expectLater(
        () => make().analyzeText('anything'),
        throwsA(isA<AnalysisException>()),
      );
    });
  });

  group('OllamaProvider.analyzeImageMulti', () {
    test('posts the shelf photo with the multi-item prompt and parses '
        'the array into one result per item', () async {
      adapter.onPost(
        'http://o.test:11434/api/generate',
        (s) => s.reply(200, {
          'response':
              '[{"name":"Bosch Drill","brand":"Bosch","category":"Tools",'
              '"estimatedRetailPrice":129.99,"confidence":0.9},'
              '{"name":"Paperback","category":"Books","confidence":0.6}]',
        }),
        data: Matchers.any,
      );

      final results = await make().analyzeImageMulti(
        Uint8List.fromList([1, 2, 3]),
      );

      expect(results, hasLength(2));
      expect(results[0].itemName, 'Bosch Drill');
      expect(results[0].brand, 'Bosch');
      expect(results[1].itemName, 'Paperback');

      final body = captured.single.data as Map<String, dynamic>;
      expect(body['images'], hasLength(1),
          reason: 'the shelf photo must ride along');
      expect(
        (body['prompt'] as String).toLowerCase(),
        contains('each distinct'),
        reason: 'multi analysis must use the multi-item prompt',
      );
      expect(body['stream'], isFalse);
    });

    test('malformed entries are dropped, good ones kept — no crash', () async {
      adapter.onPost(
        'http://o.test:11434/api/generate',
        (s) => s.reply(200, {
          'response': '[{"name":"Vase"},"garbage",{"category":"Tools"}]',
        }),
        data: Matchers.any,
      );

      final results = await make().analyzeImageMulti(Uint8List(1));

      expect(results, hasLength(1));
      expect(results.single.itemName, 'Vase');
    });

    test('HTTP failure surfaces as typed AnalysisException', () async {
      adapter.onPost(
        'http://o.test:11434/api/generate',
        (s) => s.reply(500, {'error': 'boom'}),
        data: Matchers.any,
      );

      await expectLater(
        () => make().analyzeImageMulti(Uint8List(1)),
        throwsA(isA<AnalysisException>()),
      );
    });
  });
}

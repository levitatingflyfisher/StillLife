import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:still_life/services/ml/hosted_provider.dart';
import 'package:still_life/services/ml/ollama_provider.dart'
    show AnalysisException;

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
  });

  HostedProvider make({required String bearer}) => HostedProvider(
    dio: dio,
    baseUrl: 'https://w.test',
    apiKeyProvider: () async => bearer,
    maxRetries: 1,
  );

  test(
    '401 throws AuthRequiredException and fires onUnauthorized callback',
    () async {
      adapter.onPost(
        'https://w.test/api/v1/analyze',
        (s) => s.reply(401, {'error': 'invalid_bearer'}),
        data: Matchers.any,
      );
      var called = false;
      final p = HostedProvider(
        dio: dio,
        baseUrl: 'https://w.test',
        apiKeyProvider: () async => 'sl_live_bad',
        onUnauthorized: () async {
          called = true;
        },
        maxRetries: 1,
      );
      await expectLater(
        () => p.analyzeImage(imageBytes: Uint8List(4)),
        throwsA(isA<AuthRequiredException>()),
      );
      expect(called, isTrue);
    },
  );

  test('429 quota_exceeded throws QuotaExceededException (no retry)', () async {
    adapter.onPost(
      'https://w.test/api/v1/analyze',
      (s) => s.reply(429, {'error': 'quota_exceeded'}),
      data: Matchers.any,
    );
    final p = make(bearer: 'sl_live_ok');
    await expectLater(
      () => p.analyzeImage(imageBytes: Uint8List(4)),
      throwsA(isA<QuotaExceededException>()),
    );
  });

  test('503 retries then throws AnalysisException', () async {
    adapter.onPost(
      'https://w.test/api/v1/analyze',
      (s) => s.reply(503, {'error': 'upstream'}),
      data: Matchers.any,
    );
    final p = make(bearer: 'sl_live_ok');
    await expectLater(
      () => p.analyzeImage(imageBytes: Uint8List(4)),
      throwsA(isA<AnalysisException>()),
    );
  });

  test('bearer is read fresh on each call (hot-swap)', () async {
    var currentBearer = 'sl_live_v1';
    adapter.onPost(
      'https://w.test/api/v1/analyze',
      (s) => s.reply(200, {
        'item_name': 'Test Item',
        'description': 'desc',
        'category': 'Other',
        'confidence': 0.9,
      }),
      data: Matchers.any,
    );
    final p = HostedProvider(
      dio: dio,
      baseUrl: 'https://w.test',
      apiKeyProvider: () async => currentBearer,
      maxRetries: 1,
    );
    final r1 = await p.analyzeImage(imageBytes: Uint8List(4));
    expect(r1.itemName, 'Test Item');

    // Rotate the bearer; next call must see the new value.
    currentBearer = 'sl_live_v2';
    final r2 = await p.analyzeImage(imageBytes: Uint8List(4));
    expect(r2.itemName, 'Test Item');
  });

  test('successful 200 parses AnalysisResult', () async {
    adapter.onPost(
      'https://w.test/api/v1/analyze',
      (s) => s.reply(200, {
        'item_name': 'Blender',
        'brand': 'Vitamix',
        'model': '5200',
        'description': 'Professional blender',
        'category': 'Appliances',
        'estimated_price': 499.99,
        'confidence': 0.92,
      }),
      data: Matchers.any,
    );
    final p = make(bearer: 'sl_live_ok');
    final r = await p.analyzeImage(imageBytes: Uint8List(4));
    expect(r.itemName, 'Blender');
    expect(r.brand, 'Vitamix');
    expect(r.model, '5200');
    expect(r.category, 'Appliances');
    expect(r.estimatedPrice, 499.99);
    expect(r.confidence, closeTo(0.92, 1e-6));
  });

  test(
    'isAvailable returns false when apiKeyProvider yields empty string',
    () async {
      final p = HostedProvider(
        dio: dio,
        baseUrl: 'https://w.test',
        apiKeyProvider: () async => '',
      );
      expect(await p.isAvailable(), isFalse);
    },
  );
}

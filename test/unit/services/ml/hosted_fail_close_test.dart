import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/providers/billing_providers.dart';
import 'package:still_life/services/ml/hosted_messages_client.dart';
import 'package:still_life/services/ml/hosted_provider.dart';
import 'package:still_life/services/ml/ollama_provider.dart'
    show AnalysisException;

void main() {
  late Dio dio;
  late List<RequestOptions> attempted;

  setUp(() {
    dio = Dio();
    attempted = [];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          attempted.add(options);
          handler.next(options);
        },
      ),
    );
  });

  test('kHostedBaseUrl defaults to empty — never a host we do not own', () {
    // Debug/test builds carry no --dart-define=HOSTED_BASE_URL; sending
    // bearers and photos to a placeholder domain would leak them to
    // whoever registers it.
    expect(kHostedBaseUrl, isEmpty);
  });

  test('kCheckoutUrl defaults to empty — same never-a-domain-we-do-not-own '
      'rule as kHostedBaseUrl, but for a PAYMENT page', () {
    // The old default pointed the Upgrade button at an unowned,
    // registrable domain presented as a Stripe checkout. Fail closed.
    expect(kCheckoutUrl, isEmpty);
  });

  group('HostedProvider with empty baseUrl (fail closed)', () {
    HostedProvider make() => HostedProvider(
      dio: dio,
      baseUrl: '',
      apiKeyProvider: () async => 'sl_live_configured',
      maxRetries: 1,
    );

    test('reports unavailable and attempts no HTTP', () async {
      expect(await make().isAvailable(), isFalse);
      expect(attempted, isEmpty);
    });

    test('analyzeImage throws typed AnalysisException, no HTTP', () async {
      await expectLater(
        () => make().analyzeImage(imageBytes: Uint8List(4)),
        throwsA(isA<AnalysisException>()),
      );
      expect(attempted, isEmpty);
    });

    test('analyzeText throws typed AnalysisException, no HTTP', () async {
      await expectLater(
        () => make().analyzeText('prompt'),
        throwsA(isA<AnalysisException>()),
      );
      expect(attempted, isEmpty);
    });
  });

  group('HostedMessagesClient with empty baseUrl (fail closed)', () {
    HostedMessagesClient make() => HostedMessagesClient(
      dio: dio,
      baseUrl: '',
      apiKeyProvider: () async => 'sl_live_configured',
    );

    test('send returns typed ValidationFailure, no HTTP', () async {
      final r = await make().send({'model': 'x'});
      expect(r.isFailure, isTrue);
      expect(r.failure, isA<ValidationFailure>());
      expect(attempted, isEmpty);
    });

    test('sendStream throws StateError, no HTTP', () async {
      await expectLater(
        () => make().sendStream({'model': 'x'}).toList(),
        throwsStateError,
      );
      expect(attempted, isEmpty);
    });
  });
}

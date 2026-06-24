import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/services/appraisal/messages_transport_adapter.dart';
import 'package:still_life/services/ml/cloud_api_provider.dart';
import 'package:still_life/services/ml/hosted_messages_client.dart';

class _FakeHosted implements HostedMessagesClient {
  bool sendCalled = false;
  Result<Map<String, dynamic>> sendResult = const Success({'content': []});
  Object? sendThrow;
  @override
  Future<String> Function() get apiKeyProvider =>
      () async => '';
  @override
  String get baseUrl => 'https://example.test';
  @override
  Future<Result<Map<String, dynamic>>> send(Map<String, dynamic> body) async {
    sendCalled = true;
    final t = sendThrow;
    if (t != null) throw t;
    return sendResult;
  }

  @override
  Stream<String> sendStream(Map<String, dynamic> body) async* {
    final t = sendThrow;
    if (t != null) throw t;
  }
}

class _StubCloud extends CloudApiProvider {
  final Result<Map<String, dynamic>> result;
  bool called = false;
  _StubCloud(this.result)
    : super(dio: Dio(), apiKey: 'sk-byo', apiType: CloudApiType.claude);

  @override
  Future<Result<Map<String, dynamic>>> sendMessages(
    Map<String, dynamic> body,
  ) async {
    called = true;
    return result;
  }
}

void main() {
  group('MessagesTransportAdapter', () {
    test('uses hosted client when hosted is available', () async {
      final hosted = _FakeHosted();
      final adapter = MessagesTransportAdapter(
        hosted: hosted,
        cloudApiFactory: () => CloudApiProvider(
          dio: Dio(),
          apiKey: 'irrelevant',
          apiType: CloudApiType.claude,
        ),
        isHostedAvailable: () async => true,
      );
      final r = await adapter.send({'model': 'x'});
      expect(hosted.sendCalled, isTrue);
      expect(r.isSuccess, isTrue);
    });

    test('returns ValidationFailure when nothing is configured', () async {
      final adapter = MessagesTransportAdapter(
        hosted: _FakeHosted(),
        cloudApiFactory: () => CloudApiProvider(
          dio: Dio(),
          apiKey: '',
          apiType: CloudApiType.claude,
        ),
        isHostedAvailable: () async => false,
      );
      final r = await adapter.send({'model': 'x'});
      expect(r.isFailure, isTrue);
      expect(r.failure, isA<ValidationFailure>());
    });

    test('falls back to BYO when hosted returns 401 DioException', () async {
      final hosted = _FakeHosted();
      hosted.sendThrow = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 401,
        ),
      );
      final cloud = _StubCloud(const Success({'content': []}));
      final adapter = MessagesTransportAdapter(
        hosted: hosted,
        cloudApiFactory: () => cloud,
        isHostedAvailable: () async => true,
      );
      final r = await adapter.send({'model': 'x'});
      expect(r.isSuccess, isTrue);
      expect(cloud.called, isTrue);
    });

    test(
      'falls back to BYO when hosted returns UnauthenticatedFailure',
      () async {
        final hosted = _FakeHosted();
        hosted.sendResult = const Err(UnauthenticatedFailure());
        final cloud = _StubCloud(const Success({'content': []}));
        final adapter = MessagesTransportAdapter(
          hosted: hosted,
          cloudApiFactory: () => cloud,
          isHostedAvailable: () async => true,
        );
        final r = await adapter.send({'model': 'x'});
        expect(r.isSuccess, isTrue);
        expect(cloud.called, isTrue);
      },
    );

    test(
      'returns ValidationFailure when cloud provider is OpenAI (no messages support)',
      () async {
        final adapter = MessagesTransportAdapter(
          hosted: _FakeHosted(),
          cloudApiFactory: () => CloudApiProvider(
            dio: Dio(),
            apiKey: 'sk-xxx',
            apiType: CloudApiType.openai,
          ),
          isHostedAvailable: () async => false,
        );
        final r = await adapter.send({'model': 'x'});
        expect(r.isFailure, isTrue);
      },
    );
  });
}

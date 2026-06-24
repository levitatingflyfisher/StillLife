import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/services/ml/hosted_messages_client.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late HostedMessagesClient client;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    client = HostedMessagesClient(
      dio: dio,
      baseUrl: 'https://w.test',
      apiKeyProvider: () async => 'sl_live_ok',
    );
  });

  test('happy path: 200 returns parsed body', () async {
    adapter.onPost(
      'https://w.test/v1/messages',
      (s) => s.reply(200, {
        'id': 'msg_123',
        'content': [
          {'type': 'text', 'text': 'hello'},
        ],
      }),
      data: Matchers.any,
    );
    final r = await client.send({'model': 'claude-3-5-sonnet'});
    r.when(
      success: (data) {
        expect(data['id'], 'msg_123');
      },
      failure: (f) => fail('expected success, got ${f.message}'),
    );
  });

  test('429 maps to QuotaExceededFailure', () async {
    adapter.onPost(
      'https://w.test/v1/messages',
      (s) => s.reply(429, {'error': 'quota_exceeded'}),
      data: Matchers.any,
    );
    final r = await client.send({'model': 'claude'});
    expect(r.isFailure, isTrue);
    r.when(
      success: (_) => fail('expected failure'),
      failure: (f) => expect(f, isA<QuotaExceededFailure>()),
    );
  });

  test('401 maps to UnauthenticatedFailure', () async {
    adapter.onPost(
      'https://w.test/v1/messages',
      (s) => s.reply(401, {'error': 'invalid_bearer'}),
      data: Matchers.any,
    );
    final r = await client.send({'model': 'claude'});
    r.when(
      success: (_) => fail('expected failure'),
      failure: (f) => expect(f, isA<UnauthenticatedFailure>()),
    );
  });

  test('other errors map to NetworkFailure', () async {
    adapter.onPost(
      'https://w.test/v1/messages',
      (s) => s.reply(500, {'error': 'boom'}),
      data: Matchers.any,
    );
    final r = await client.send({'model': 'claude'});
    r.when(
      success: (_) => fail('expected failure'),
      failure: (f) => expect(f, isA<NetworkFailure>()),
    );
  });
}

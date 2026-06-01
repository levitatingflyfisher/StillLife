import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../ml/cloud_api_provider.dart';
import '../ml/hosted_messages_client.dart';
import 'appraiser_service.dart';

/// Production [MessagesTransport]: tries the hosted proxy first when the user
/// has a Pro bearer configured, falls back to the BYO Anthropic API key. If
/// neither is configured returns a [ValidationFailure].
class MessagesTransportAdapter implements MessagesTransport {
  final HostedMessagesClient hosted;
  final CloudApiProvider Function() cloudApiFactory;
  final Future<bool> Function() isHostedAvailable;

  MessagesTransportAdapter({
    required this.hosted,
    required this.cloudApiFactory,
    required this.isHostedAvailable,
  });

  @override
  Future<Result<Map<String, dynamic>>> send(Map<String, dynamic> body) async {
    if (await isHostedAvailable()) {
      try {
        final r = await hosted.send(body);
        // Hosted may return a typed UnauthenticatedFailure on 401 — also
        // try BYO in that case.
        if (r is Err<Map<String, dynamic>> &&
            r.failure is UnauthenticatedFailure) {
          return _tryByoSend(body);
        }
        return r;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          return _tryByoSend(body);
        }
        rethrow;
      }
    }
    return _tryByoSend(body);
  }

  Future<Result<Map<String, dynamic>>> _tryByoSend(
    Map<String, dynamic> body,
  ) async {
    final cloud = cloudApiFactory();
    if (cloud.apiKey.isNotEmpty && cloud.apiType == CloudApiType.claude) {
      return cloud.sendMessages(body);
    }
    return const Err(
      ValidationFailure(
        'No LLM provider configured. Add a Claude API key or sign in to Pro.',
      ),
    );
  }

  /// Mirrors [send] but yields SSE text deltas.
  Stream<String> sendStream(Map<String, dynamic> body) async* {
    if (await isHostedAvailable()) {
      try {
        yield* hosted.sendStream(body);
        return;
      } on DioException catch (e) {
        if (e.response?.statusCode != 401) rethrow;
        // Fall through to BYO on a hosted-side 401.
      }
    }
    final cloud = cloudApiFactory();
    if (cloud.apiKey.isNotEmpty && cloud.apiType == CloudApiType.claude) {
      yield* cloud.streamMessages(body);
      return;
    }
    throw StateError(
      'No LLM provider configured. Add a Claude API key or sign in to Pro.',
    );
  }
}

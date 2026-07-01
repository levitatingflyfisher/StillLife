import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/appraisal/data/repositories/appraisal_repository_impl.dart';
import '../../features/appraisal/domain/entities/appraisal.dart';
import '../../features/appraisal/domain/repositories/appraisal_repository.dart';
import '../../features/billing/data/stripe_billing_service_impl.dart'
    show kHostedBearerStorageKey;
import '../../services/appraisal/appraiser_prompt.dart'
    show kAppraiserDefaultModel;
import '../../services/appraisal/appraiser_service.dart';
import '../../core/errors/result.dart';
import 'cloud_api_settings.dart' show kAppraiserModelStorageKey;
import '../../services/appraisal/messages_transport_adapter.dart';
import '../../services/ml/cloud_api_provider.dart';
import '../../services/ml/hosted_messages_client.dart';
import 'billing_providers.dart' show kHostedBaseUrl;
import 'database_provider.dart';

/// Drift-backed [AppraisalRepository] singleton.
final appraisalRepositoryProvider = Provider<AppraisalRepository>((ref) {
  return AppraisalRepositoryImpl(ref.watch(databaseProvider));
});

/// Infers the device country from the platform locale (e.g. "en_US" → "US").
/// Uses PlatformDispatcher, which exists on native AND web — dart:io's
/// Platform.localeName does not. Defaults to "US" when we cannot parse.
final appraiserCountryCodeProvider = Provider<String Function()>((ref) {
  return () {
    try {
      final locale = ui.PlatformDispatcher.instance.locale.toString();
      final match = RegExp(r'[_-]([A-Z]{2})').firstMatch(locale);
      return match?.group(1) ?? 'US';
    } catch (_) {
      return 'US';
    }
  };
});

/// Dio instance dedicated to the appraiser's SSE + JSON calls so we can
/// configure it independently from the per-tier ML Dio.
final _appraiserDioProvider = Provider<Dio>((ref) => Dio());

/// Hosted Messages client reused by both Appraiser and ItemChat features.
final hostedMessagesClientProvider = Provider<HostedMessagesClient>((ref) {
  return HostedMessagesClient(
    dio: ref.watch(_appraiserDioProvider),
    baseUrl: kHostedBaseUrl,
    apiKeyProvider: () async {
      const storage = FlutterSecureStorage();
      return (await storage.read(key: kHostedBearerStorageKey)) ?? '';
    },
  );
});

/// Loads the BYO Anthropic key from secure storage and wraps it in a
/// [CloudApiProvider]. Reads storage on every call so key updates take
/// effect without a restart.
Future<CloudApiProvider> _buildCloudApiProvider(Dio dio) async {
  const storage = FlutterSecureStorage();
  final key = (await storage.read(key: 'claude_api_key')) ?? '';
  return CloudApiProvider(dio: dio, apiKey: key, apiType: CloudApiType.claude);
}

/// Production [MessagesTransport]: hosted-first, BYO fallback.
final messagesTransportProvider = Provider<MessagesTransport>((ref) {
  final hosted = ref.watch(hostedMessagesClientProvider);
  final dio = ref.watch(_appraiserDioProvider);
  return _LazyMessagesTransport(
    hosted: hosted,
    buildCloud: () => _buildCloudApiProvider(dio),
    isHostedAvailable: () async {
      // No configured backend → hosted path is off; go straight to BYO.
      if (kHostedBaseUrl.isEmpty) return false;
      const storage = FlutterSecureStorage();
      final bearer = await storage.read(key: kHostedBearerStorageKey);
      return (bearer ?? '').isNotEmpty;
    },
  );
});

/// Transport that resolves the cloud provider asynchronously on each call.
/// Avoids the sync-cloud-factory trap inside [MessagesTransportAdapter].
class _LazyMessagesTransport implements MessagesTransport {
  final HostedMessagesClient hosted;
  final Future<CloudApiProvider> Function() buildCloud;
  final Future<bool> Function() isHostedAvailable;

  _LazyMessagesTransport({
    required this.hosted,
    required this.buildCloud,
    required this.isHostedAvailable,
  });

  @override
  Future<Result<Map<String, dynamic>>> send(Map<String, dynamic> body) async {
    final cloud = await buildCloud();
    final adapter = MessagesTransportAdapter(
      hosted: hosted,
      cloudApiFactory: () => cloud,
      isHostedAvailable: isHostedAvailable,
    );
    return adapter.send(body);
  }

  /// Mirrors the adapter's streaming path. Resolves the cloud provider once
  /// then yields deltas.
  Stream<String> sendStream(Map<String, dynamic> body) async* {
    final cloud = await buildCloud();
    final adapter = MessagesTransportAdapter(
      hosted: hosted,
      cloudApiFactory: () => cloud,
      isHostedAvailable: isHostedAvailable,
    );
    yield* adapter.sendStream(body);
  }
}

/// The orchestrator: checks cache, calls LLM, parses, persists.
final appraiserServiceProvider = Provider<AppraiserService>((ref) {
  return AppraiserService(
    repo: ref.watch(appraisalRepositoryProvider),
    transport: ref.watch(messagesTransportProvider),
    countryCode: ref.watch(appraiserCountryCodeProvider),
    // Read storage on every call (like the BYO key) so a model change in
    // settings takes effect without a restart.
    model: () async {
      const storage = FlutterSecureStorage();
      final saved = await storage.read(key: kAppraiserModelStorageKey);
      return (saved == null || saved.trim().isEmpty)
          ? kAppraiserDefaultModel
          : saved;
    },
  );
});

/// Latest fresh appraisal for `(itemId, mode)`, or null.
final latestAppraisalProvider = FutureProvider.autoDispose
    .family<Appraisal?, ({String itemId, AppraisalMode mode})>((ref, key) {
      return ref
          .watch(appraisalRepositoryProvider)
          .getLatestByItemAndMode(key.itemId, key.mode);
    });

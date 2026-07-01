import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/ml/cloud_api_provider.dart' show CloudApiType;

/// Secure-storage keys for the BYO cloud tier (tier 3).
///
/// `cloud_api_type` selects which config the tier uses ('claude'|'openai').
/// The OpenAI-compatible trio allows pointing the tier at any
/// chat/completions server (OpenAI, llamafile, LM Studio, vLLM, ...).
const String kCloudApiTypeStorageKey = 'cloud_api_type';
const String kClaudeApiKeyStorageKey = 'claude_api_key';
const String kOpenAiCompatApiKeyStorageKey = 'openai_compat_api_key';
const String kOpenAiCompatBaseUrlStorageKey = 'openai_compat_base_url';
const String kOpenAiCompatModelStorageKey = 'openai_compat_model';

/// Legacy slot written by older builds' settings screen. Used as the
/// fallback initial value for [kOpenAiCompatApiKeyStorageKey].
const String kLegacyOpenAiApiKeyStorageKey = 'openai_api_key';

/// Removed hosted-tier key slot older builds wrote. Never read anymore
/// (the hosted tier authenticates with `hosted_bearer`); deleted at
/// config load so the orphaned secret doesn't sit in the platform
/// keystore forever.
const String kLegacyHostedApiKeyStorageKey = 'hosted_api_key';

/// Anthropic model id used by the Appraiser feature (market-value
/// estimates). Empty/absent means the default in `appraiser_prompt.dart`.
const String kAppraiserModelStorageKey = 'appraiser_model_v1';

const String kOpenAiCompatDefaultBaseUrl = 'https://api.openai.com/v1';
const String kOpenAiCompatDefaultModel = 'gpt-4o';

/// Injectable secure-storage instance so provider wiring can be tested
/// without platform channels.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Resolved configuration for the BYO cloud tier.
class CloudApiConfig {
  final CloudApiType apiType;
  final String claudeApiKey;
  final String openAiApiKey;
  final String openAiBaseUrl;
  final String openAiModel;

  const CloudApiConfig({
    required this.apiType,
    required this.claudeApiKey,
    required this.openAiApiKey,
    required this.openAiBaseUrl,
    required this.openAiModel,
  });

  /// The API key belonging to the selected [apiType].
  String get selectedApiKey =>
      apiType == CloudApiType.claude ? claudeApiKey : openAiApiKey;
}

/// Loads the cloud-tier config from secure storage.
///
/// When no `cloud_api_type` has been stored, the type is inferred from
/// whichever key the user actually stored — a stored key must never leave
/// the tier dead.
final cloudApiConfigProvider = FutureProvider<CloudApiConfig>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  Future<String> read(String key) async =>
      (await storage.read(key: key)) ?? '';

  // One-time cleanup of the removed hosted_api_key slot (see the
  // constant's doc). Best-effort: a failing delete must not kill config
  // loading.
  try {
    await storage.delete(key: kLegacyHostedApiKeyStorageKey);
  } catch (_) {}

  final claudeKey = await read(kClaudeApiKeyStorageKey);
  var openAiKey = await read(kOpenAiCompatApiKeyStorageKey);
  if (openAiKey.isEmpty) {
    openAiKey = await read(kLegacyOpenAiApiKeyStorageKey);
  }
  var openAiBaseUrl = await read(kOpenAiCompatBaseUrlStorageKey);
  if (openAiBaseUrl.isEmpty) openAiBaseUrl = kOpenAiCompatDefaultBaseUrl;
  var openAiModel = await read(kOpenAiCompatModelStorageKey);
  if (openAiModel.isEmpty) openAiModel = kOpenAiCompatDefaultModel;

  final apiType = switch (await read(kCloudApiTypeStorageKey)) {
    'claude' => CloudApiType.claude,
    'openai' => CloudApiType.openai,
    _ => claudeKey.isNotEmpty ? CloudApiType.claude : CloudApiType.openai,
  };

  return CloudApiConfig(
    apiType: apiType,
    claudeApiKey: claudeKey,
    openAiApiKey: openAiKey,
    openAiBaseUrl: openAiBaseUrl,
    openAiModel: openAiModel,
  );
});

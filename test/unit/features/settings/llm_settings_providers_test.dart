import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/providers/cloud_api_settings.dart';
import 'package:still_life/features/settings/presentation/screens/llm_settings_screen.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/cloud_api_provider.dart' show CloudApiType;

/// In-memory fake for flutter_secure_storage to avoid platform channels in tests.
class _FakeSecureStorage {
  final Map<String, String> values = {};

  void install() {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'read':
              final key = (call.arguments as Map)['key'] as String;
              return values[key];
            case 'write':
              final args = call.arguments as Map;
              values[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              final args = call.arguments as Map;
              values.remove(args['key'] as String);
              return null;
            case 'readAll':
              return Map<String, String>.from(values);
            case 'deleteAll':
              values.clear();
              return null;
            case 'containsKey':
              final key = (call.arguments as Map)['key'] as String;
              return values.containsKey(key);
          }
          return null;
        });
  }

  void uninstall() {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }
}

void main() {
  late _FakeSecureStorage fake;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    fake = _FakeSecureStorage()..install();
  });

  tearDown(() {
    fake.uninstall();
  });

  test('llmTierPriorityProvider defaults put on-device LAST — an '
      'always-available coarse labeler must never shadow a configured '
      'VLM tier', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final priority = await container.read(llmTierPriorityProvider.future);
    expect(priority, kDefaultTierPriority);
    expect(priority.last, AnalysisTier.onDevice);
    expect(priority.toSet(), AnalysisTier.values.toSet(),
        reason: 'every tier is represented exactly once');
  });

  test('reconciliation appends tiers missing from an old persisted value '
      'in default order (on-device last)', () async {
    // An old install that persisted only two tiers.
    final container0 = ProviderContainer();
    addTearDown(container0.dispose);
    await container0.read(llmTierPriorityProvider.future);
    fake.values['llm_tier_priority_v1'] = 'hosted,cloudApi';

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final priority = await container.read(llmTierPriorityProvider.future);
    expect(priority, [
      AnalysisTier.hosted,
      AnalysisTier.cloudApi,
      AnalysisTier.localLlm,
      AnalysisTier.onDevice,
    ]);
  });

  test('llmTierPriorityProvider persists order via setOrder', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(llmTierPriorityProvider.future);
    final newOrder = [
      AnalysisTier.hosted,
      AnalysisTier.cloudApi,
      AnalysisTier.localLlm,
      AnalysisTier.onDevice,
    ];
    await container.read(llmTierPriorityProvider.notifier).setOrder(newOrder);
    expect(container.read(llmTierPriorityProvider).valueOrNull, newOrder);

    // Simulate cold start: new container reads persisted value.
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    final reloaded = await container2.read(llmTierPriorityProvider.future);
    expect(reloaded, newOrder);
  });

  test('llmTierEnabledProvider persists toggles', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(llmTierEnabledProvider.future);
    // Privacy invariant: the local-LLM tier probes (and would hand
    // photos to) whatever answers on localhost:11434 — it must be an
    // explicit opt-in, never enabled by default.
    final defaults = {
      for (final t in AnalysisTier.values) t: t != AnalysisTier.localLlm,
    };
    expect(container.read(llmTierEnabledProvider).valueOrNull, defaults);

    final updated = Map<AnalysisTier, bool>.from(defaults);
    updated[AnalysisTier.hosted] = false;
    await container.read(llmTierEnabledProvider.notifier).setEnabled(updated);

    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    final reloaded = await container2.read(llmTierEnabledProvider.future);
    expect(reloaded[AnalysisTier.hosted], isFalse);
    expect(reloaded[AnalysisTier.onDevice], isTrue);
  });

  test('ollamaHostProvider persists host string', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(ollamaHostProvider.future), 'localhost');
    await container.read(ollamaHostProvider.notifier).setHost('192.168.1.50');

    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(await container2.read(ollamaHostProvider.future), '192.168.1.50');
  });

  test('ollamaPortProvider persists port int', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(ollamaPortProvider.future), 11434);
    await container.read(ollamaPortProvider.notifier).setPort(11500);

    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(await container2.read(ollamaPortProvider.future), 11500);
  });

  test('ollamaModelProvider persists model string', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(ollamaModelProvider.future), 'llava');
    await container.read(ollamaModelProvider.notifier).setModel('qwen2.5vl');

    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(await container2.read(ollamaModelProvider.future), 'qwen2.5vl');
  });

  group('cloud API settings providers', () {
    test('cloudApiTypeSettingProvider defaults to openai when nothing is '
        'stored', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        await container.read(cloudApiTypeSettingProvider.future),
        CloudApiType.openai,
      );
    });

    test('cloudApiTypeSettingProvider infers claude when only a Claude key '
        'is stored (mirrors the core inference)', () async {
      fake.values[kClaudeApiKeyStorageKey] = 'sk-ant-stored';
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        await container.read(cloudApiTypeSettingProvider.future),
        CloudApiType.claude,
      );
    });

    test('setType persists to the cloud_api_type key the core consumes and '
        'refreshes the core config', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(cloudApiTypeSettingProvider.future);

      await container
          .read(cloudApiTypeSettingProvider.notifier)
          .setType(CloudApiType.claude);

      expect(fake.values[kCloudApiTypeStorageKey], 'claude');
      // The provider the analysis tier actually reads must see the change
      // without an app restart.
      final config = await container.read(cloudApiConfigProvider.future);
      expect(config.apiType, CloudApiType.claude);
    });

    test('claudeApiKeySettingProvider persists to claude_api_key and '
        'refreshes the core config', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(claudeApiKeySettingProvider.future);

      await container
          .read(claudeApiKeySettingProvider.notifier)
          .setKey('sk-ant-new');

      expect(fake.values[kClaudeApiKeyStorageKey], 'sk-ant-new');
      final config = await container.read(cloudApiConfigProvider.future);
      expect(config.claudeApiKey, 'sk-ant-new');
    });

    test('openAiCompatBaseUrlProvider defaults to the core default and '
        'persists to openai_compat_base_url', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        await container.read(openAiCompatBaseUrlProvider.future),
        kOpenAiCompatDefaultBaseUrl,
      );

      await container
          .read(openAiCompatBaseUrlProvider.notifier)
          .setBaseUrl('http://localhost:8080/v1');

      expect(
        fake.values[kOpenAiCompatBaseUrlStorageKey],
        'http://localhost:8080/v1',
      );
      final config = await container.read(cloudApiConfigProvider.future);
      expect(config.openAiBaseUrl, 'http://localhost:8080/v1');
    });

    test('openAiCompatApiKeyProvider prefills from the legacy '
        'openai_api_key slot', () async {
      fake.values[kLegacyOpenAiApiKeyStorageKey] = 'sk-legacy';
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        await container.read(openAiCompatApiKeyProvider.future),
        'sk-legacy',
      );
    });

    test('openAiCompatApiKeyProvider persists to openai_compat_api_key', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(await container.read(openAiCompatApiKeyProvider.future), '');

      await container
          .read(openAiCompatApiKeyProvider.notifier)
          .setKey('sk-compat');

      expect(fake.values[kOpenAiCompatApiKeyStorageKey], 'sk-compat');
      final config = await container.read(cloudApiConfigProvider.future);
      expect(config.openAiApiKey, 'sk-compat');
    });

    test('openAiCompatModelProvider defaults to the core default and '
        'persists to openai_compat_model', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        await container.read(openAiCompatModelProvider.future),
        kOpenAiCompatDefaultModel,
      );

      await container
          .read(openAiCompatModelProvider.notifier)
          .setModel('llava:13b');

      expect(fake.values[kOpenAiCompatModelStorageKey], 'llava:13b');
      final config = await container.read(cloudApiConfigProvider.future);
      expect(config.openAiModel, 'llava:13b');
    });
  });

  group('appraiser model setting', () {
    test('defaults to claude-sonnet-4-6 when nothing is stored', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        await container.read(appraiserModelSettingProvider.future),
        'claude-sonnet-4-6',
      );
    });

    test('persists to appraiser_model_v1 and restores on next load',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(appraiserModelSettingProvider.notifier)
          .setModel('claude-opus-4-6');

      expect(fake.values[kAppraiserModelStorageKey], 'claude-opus-4-6');

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      expect(
        await container2.read(appraiserModelSettingProvider.future),
        'claude-opus-4-6',
      );
    });

    test('blank input falls back to the default rather than a dead model id',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(appraiserModelSettingProvider.notifier)
          .setModel('   ');
      expect(
        await container.read(appraiserModelSettingProvider.future),
        'claude-sonnet-4-6',
      );
    });
  });

  group('clearing + trimming stored credentials', () {
    test('clearing the compat key REVOKES a legacy openai_api_key too — '
        'an emptied field must stop the old key being sent', () async {
      fake.values[kLegacyOpenAiApiKeyStorageKey] = 'sk-old-revoked';
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(openAiCompatApiKeyProvider.future);

      await container.read(openAiCompatApiKeyProvider.notifier).setKey('');

      final config = await container.read(cloudApiConfigProvider.future);
      expect(config.openAiApiKey, isEmpty,
          reason: 'the loader must not resurrect the legacy slot after '
              'the user deliberately cleared the field');
      expect(fake.values.containsKey(kLegacyOpenAiApiKeyStorageKey), isFalse,
          reason: 'the legacy secret must be deleted, not left behind');
    });

    test('keys, base URL, and model are trimmed on persist — a pasted '
        'trailing CR/space must not poison headers or URLs', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(claudeApiKeySettingProvider.future);
      await container.read(openAiCompatApiKeyProvider.future);
      await container.read(openAiCompatBaseUrlProvider.future);
      await container.read(openAiCompatModelProvider.future);

      await container
          .read(claudeApiKeySettingProvider.notifier)
          .setKey('sk-ant-x\r');
      await container
          .read(openAiCompatApiKeyProvider.notifier)
          .setKey(' sk-compat-x ');
      await container
          .read(openAiCompatBaseUrlProvider.notifier)
          .setBaseUrl('https://api.openai.com/v1 ');
      await container
          .read(openAiCompatModelProvider.notifier)
          .setModel('gpt-4o\t');

      expect(fake.values[kClaudeApiKeyStorageKey], 'sk-ant-x');
      expect(fake.values[kOpenAiCompatApiKeyStorageKey], 'sk-compat-x');
      expect(fake.values[kOpenAiCompatBaseUrlStorageKey],
          'https://api.openai.com/v1');
      expect(fake.values[kOpenAiCompatModelStorageKey], 'gpt-4o');
    });

    test('a secret stored under the removed hosted_api_key slot is '
        'deleted when the cloud config loads (orphan cleanup)', () async {
      fake.values['hosted_api_key'] = 'stale-secret';
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(cloudApiConfigProvider.future);

      expect(fake.values.containsKey('hosted_api_key'), isFalse,
          reason: 'no code reads this slot anymore; the credential must '
              'not sit in the platform keystore forever');
    });
  });

  group('normalizeOllamaHost', () {
    test('strips pasted schemes and trailing slashes — the base URL is '
        'assembled as http://host:port, so a pasted URL must not yield '
        'http://https://...', () {
      expect(normalizeOllamaHost('https://192.168.1.20'), '192.168.1.20');
      expect(normalizeOllamaHost('http://ollama.local/'), 'ollama.local');
      expect(normalizeOllamaHost(' 192.168.1.20 '), '192.168.1.20');
      expect(normalizeOllamaHost('192.168.1.20'), '192.168.1.20');
    });

    test('setHost persists the normalized host', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(ollamaHostProvider.future);
      await container
          .read(ollamaHostProvider.notifier)
          .setHost('http://192.168.1.20/');
      expect(fake.values['ollama_host_v1'], '192.168.1.20');
    });
  });

  group('isPrivateNetworkHost', () {
    test('accepts loopback, RFC1918, link-local, ULA and mDNS/.local hosts — '
        'the only places a cleartext-HTTP Ollama may live', () {
      expect(isPrivateNetworkHost('localhost'), isTrue);
      expect(isPrivateNetworkHost('127.0.0.1'), isTrue);
      expect(isPrivateNetworkHost('::1'), isTrue);
      expect(isPrivateNetworkHost('[::1]'), isTrue);
      expect(isPrivateNetworkHost('10.0.0.5'), isTrue);
      expect(isPrivateNetworkHost('172.16.0.1'), isTrue);
      expect(isPrivateNetworkHost('172.31.255.254'), isTrue);
      expect(isPrivateNetworkHost('192.168.1.20'), isTrue);
      expect(isPrivateNetworkHost('169.254.7.9'), isTrue);
      expect(isPrivateNetworkHost('fe80::1'), isTrue);
      expect(isPrivateNetworkHost('fd12:3456::1'), isTrue);
      expect(isPrivateNetworkHost('mydesk.local'), isTrue);
      // A single-label name can only resolve via local discovery.
      expect(isPrivateNetworkHost('mydesk'), isTrue);
      // Pasted URLs normalize before classification.
      expect(isPrivateNetworkHost('https://192.168.1.20/'), isTrue);
    });

    test('rejects public addresses and internet hostnames — cleartext photo '
        'bytes must never leave the local network', () {
      expect(isPrivateNetworkHost('8.8.8.8'), isFalse);
      // One past the RFC1918 172.16/12 range.
      expect(isPrivateNetworkHost('172.32.0.1'), isFalse);
      expect(isPrivateNetworkHost('11.0.0.1'), isFalse);
      expect(isPrivateNetworkHost('example.com'), isFalse);
      expect(isPrivateNetworkHost('api.evil.io'), isFalse);
      expect(isPrivateNetworkHost('2001:4860:4860::8888'), isFalse);
      expect(isPrivateNetworkHost(''), isFalse);
    });
  });
}

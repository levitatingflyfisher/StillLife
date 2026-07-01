import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/providers/cloud_api_settings.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/settings/presentation/screens/llm_settings_screen.dart'
    show llmTierEnabledProvider, ollamaHostProvider;
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/cloud_api_provider.dart';

import '../../../mocks/fake_secure_storage_channel.dart';

void main() {
  late FakeSecureStorageChannel fake;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    fake = FakeSecureStorageChannel()..install();
  });

  tearDown(() {
    fake.uninstall();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('cloudApiConfigProvider', () {
    test('cloud_api_type=claude selects the stored Claude key', () async {
      fake.values['cloud_api_type'] = 'claude';
      fake.values['claude_api_key'] = 'sk-ant-stored';

      final cfg = await makeContainer().read(cloudApiConfigProvider.future);

      expect(cfg.apiType, CloudApiType.claude);
      expect(cfg.selectedApiKey, 'sk-ant-stored');
    });

    test('cloud_api_type=openai uses the compat trio with sensible '
        'defaults; legacy openai_api_key seeds the compat key', () async {
      fake.values['cloud_api_type'] = 'openai';
      fake.values['openai_api_key'] = 'sk-legacy';

      final cfg = await makeContainer().read(cloudApiConfigProvider.future);

      expect(cfg.apiType, CloudApiType.openai);
      expect(cfg.selectedApiKey, 'sk-legacy');
      expect(cfg.openAiBaseUrl, 'https://api.openai.com/v1');
      expect(cfg.openAiModel, 'gpt-4o');
    });

    test('openai_compat_* trio wins over the legacy key', () async {
      fake.values['cloud_api_type'] = 'openai';
      fake.values['openai_compat_api_key'] = 'sk-compat';
      fake.values['openai_api_key'] = 'sk-legacy';
      fake.values['openai_compat_base_url'] = 'http://llamafile.test:8080/v1';
      fake.values['openai_compat_model'] = 'qwen2.5-7b';

      final cfg = await makeContainer().read(cloudApiConfigProvider.future);

      expect(cfg.selectedApiKey, 'sk-compat');
      expect(cfg.openAiBaseUrl, 'http://llamafile.test:8080/v1');
      expect(cfg.openAiModel, 'qwen2.5-7b');
    });

    test('no stored type: infers claude when only a Claude key exists '
        '(a stored key must never leave the tier dead)', () async {
      fake.values['claude_api_key'] = 'sk-ant-only';

      final cfg = await makeContainer().read(cloudApiConfigProvider.future);

      expect(cfg.apiType, CloudApiType.claude);
      expect(cfg.selectedApiKey, 'sk-ant-only');
    });

    test('no stored type: infers openai when only an OpenAI key exists', () async {
      fake.values['openai_api_key'] = 'sk-openai-only';

      final cfg = await makeContainer().read(cloudApiConfigProvider.future);

      expect(cfg.apiType, CloudApiType.openai);
      expect(cfg.selectedApiKey, 'sk-openai-only');
    });
  });

  group('providerManagerProvider cloud tier', () {
    test('builds the cloud tier from stored keys — no hardcoded empty '
        'apiKey', () async {
      fake.values['cloud_api_type'] = 'claude';
      fake.values['claude_api_key'] = 'sk-ant-stored';

      final container = makeContainer();
      await container.read(cloudApiConfigProvider.future);
      final manager = container.read(providerManagerProvider);
      final cloud =
          manager.getByTier(AnalysisTier.cloudApi)! as CloudApiProvider;

      expect(cloud.apiKey, 'sk-ant-stored');
      expect(cloud.apiType, CloudApiType.claude);
      expect(await cloud.isAvailable(), isTrue);
    });

    test('cloud tier is unavailable (not crashing) when nothing is '
        'stored', () async {
      final container = makeContainer();
      await container.read(cloudApiConfigProvider.future);
      final manager = container.read(providerManagerProvider);
      final cloud =
          manager.getByTier(AnalysisTier.cloudApi)! as CloudApiProvider;

      expect(await cloud.isAvailable(), isFalse);
    });
  });

  group('providerManagerProvider — fail-closed defaults', () {
    test('with NOTHING configured the local-LLM tier is absent from the '
        'cascade (no probing of whatever squats on localhost:11434)', () {
      final manager = makeContainer().read(providerManagerProvider);
      expect(manager.hasProvider(AnalysisTier.localLlm), isFalse,
          reason: 'photo/receipt bytes must only leave the app on a tier '
              'the user explicitly configured');
      expect(manager.hasProvider(AnalysisTier.cloudApi), isTrue,
          reason: 'the cloud tier stays registered — its own isAvailable '
              'fails closed on an empty key');
    });

    test('an enabled local-LLM tier pointing at a PUBLIC host is excluded — '
        'Ollama speaks plain HTTP, and cleartext must never route to the '
        'internet now that the manifest allows non-localhost cleartext',
        () async {
      fake.values['llm_tier_enabled_v1'] =
          'onDevice:true,localLlm:true,cloudApi:true,hosted:true';
      fake.values['ollama_host_v1'] = 'api.example.com';

      final container = makeContainer();
      await container.read(llmTierEnabledProvider.future);
      await container.read(ollamaHostProvider.future);
      final manager = container.read(providerManagerProvider);

      expect(manager.hasProvider(AnalysisTier.localLlm), isFalse);
    });

    test('an enabled local-LLM tier on a private-range host stays registered',
        () async {
      fake.values['llm_tier_enabled_v1'] =
          'onDevice:true,localLlm:true,cloudApi:true,hosted:true';
      fake.values['ollama_host_v1'] = '192.168.1.20';

      final container = makeContainer();
      await container.read(llmTierEnabledProvider.future);
      await container.read(ollamaHostProvider.future);
      final manager = container.read(providerManagerProvider);

      expect(manager.hasProvider(AnalysisTier.localLlm), isTrue);
    });
  });
}

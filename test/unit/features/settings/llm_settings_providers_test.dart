import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/settings/presentation/screens/llm_settings_screen.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

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

  test('llmTierPriorityProvider returns defaults on first load', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final priority = await container.read(llmTierPriorityProvider.future);
    expect(priority, AnalysisTier.values.toList());
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
    final defaults = {for (final t in AnalysisTier.values) t: true};
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
    await container.read(ollamaModelProvider.notifier).setModel('kimi-k2');

    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(await container2.read(ollamaModelProvider.future), 'kimi-k2');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../services/ml/analysis_provider.dart';

// FlutterSecureStorage keys for persisted LLM settings.
const _kTierPriorityKey = 'llm_tier_priority_v1';
const _kTierEnabledKey = 'llm_tier_enabled_v1';
const _kOllamaHostKey = 'ollama_host_v1';
const _kOllamaPortKey = 'ollama_port_v1';
const _kOllamaModelKey = 'ollama_model_v1';

const _secureStorage = FlutterSecureStorage();

/// Persisted LLM tier priority order.
final llmTierPriorityProvider =
    AsyncNotifierProvider<LlmTierPriorityNotifier, List<AnalysisTier>>(
      LlmTierPriorityNotifier.new,
    );

class LlmTierPriorityNotifier extends AsyncNotifier<List<AnalysisTier>> {
  @override
  Future<List<AnalysisTier>> build() async {
    final saved = await _secureStorage.read(key: _kTierPriorityKey);
    if (saved == null || saved.isEmpty) return AnalysisTier.values.toList();
    final tiers = <AnalysisTier>[];
    for (final name in saved.split(',')) {
      try {
        tiers.add(AnalysisTier.values.byName(name));
      } catch (_) {
        // Skip unknown names from older app versions.
      }
    }
    // Ensure all tiers are represented (append any missing in default order).
    for (final t in AnalysisTier.values) {
      if (!tiers.contains(t)) tiers.add(t);
    }
    return tiers;
  }

  Future<void> setOrder(List<AnalysisTier> order) async {
    await _secureStorage.write(
      key: _kTierPriorityKey,
      value: order.map((t) => t.name).join(','),
    );
    state = AsyncData(order);
  }
}

/// Persisted LLM tier enable/disable toggles.
final llmTierEnabledProvider =
    AsyncNotifierProvider<LlmTierEnabledNotifier, Map<AnalysisTier, bool>>(
      LlmTierEnabledNotifier.new,
    );

class LlmTierEnabledNotifier extends AsyncNotifier<Map<AnalysisTier, bool>> {
  @override
  Future<Map<AnalysisTier, bool>> build() async {
    final saved = await _secureStorage.read(key: _kTierEnabledKey);
    final defaults = {for (final t in AnalysisTier.values) t: true};
    if (saved == null || saved.isEmpty) return defaults;
    for (final entry in saved.split(',')) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      try {
        final tier = AnalysisTier.values.byName(parts[0]);
        defaults[tier] = parts[1] == 'true';
      } catch (_) {
        // Skip malformed entries.
      }
    }
    return defaults;
  }

  Future<void> setEnabled(Map<AnalysisTier, bool> enabled) async {
    final encoded = enabled.entries
        .map((e) => '${e.key.name}:${e.value}')
        .join(',');
    await _secureStorage.write(key: _kTierEnabledKey, value: encoded);
    state = AsyncData(enabled);
  }
}

/// Ollama host configuration.
final ollamaHostProvider = AsyncNotifierProvider<OllamaHostNotifier, String>(
  OllamaHostNotifier.new,
);

class OllamaHostNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    return (await _secureStorage.read(key: _kOllamaHostKey)) ?? 'localhost';
  }

  Future<void> setHost(String host) async {
    await _secureStorage.write(key: _kOllamaHostKey, value: host);
    state = AsyncData(host);
  }
}

final ollamaPortProvider = AsyncNotifierProvider<OllamaPortNotifier, int>(
  OllamaPortNotifier.new,
);

class OllamaPortNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final saved = await _secureStorage.read(key: _kOllamaPortKey);
    return int.tryParse(saved ?? '') ?? 11434;
  }

  Future<void> setPort(int port) async {
    await _secureStorage.write(key: _kOllamaPortKey, value: port.toString());
    state = AsyncData(port);
  }
}

final ollamaModelProvider = AsyncNotifierProvider<OllamaModelNotifier, String>(
  OllamaModelNotifier.new,
);

class OllamaModelNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    return (await _secureStorage.read(key: _kOllamaModelKey)) ?? 'llava';
  }

  Future<void> setModel(String model) async {
    await _secureStorage.write(key: _kOllamaModelKey, value: model);
    state = AsyncData(model);
  }
}

/// Cloud API provider selection.
enum CloudApiType { openai, claude }

final cloudApiTypeProvider = StateProvider<CloudApiType>(
  (ref) => CloudApiType.openai,
);

class LlmSettingsScreen extends ConsumerStatefulWidget {
  const LlmSettingsScreen({super.key});

  @override
  ConsumerState<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends ConsumerState<LlmSettingsScreen> {
  final _ollamaHostController = TextEditingController();
  final _ollamaPortController = TextEditingController();
  final _openAiKeyController = TextEditingController();
  final _claudeKeyController = TextEditingController();
  final _hostedKeyController = TextEditingController();

  bool _ollamaConnected = false;
  bool _testingOllama = false;
  bool _testingCloud = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadApiKeys();
  }

  Future<void> _loadSettings() async {
    final host = await ref.read(ollamaHostProvider.future);
    final port = await ref.read(ollamaPortProvider.future);
    if (mounted) {
      setState(() {
        _ollamaHostController.text = host;
        _ollamaPortController.text = port.toString();
      });
    }
  }

  Future<void> _loadApiKeys() async {
    final openAiKey = await _secureStorage.read(key: 'openai_api_key');
    final claudeKey = await _secureStorage.read(key: 'claude_api_key');
    final hostedKey = await _secureStorage.read(key: 'hosted_api_key');
    if (mounted) {
      setState(() {
        if (openAiKey != null) _openAiKeyController.text = openAiKey;
        if (claudeKey != null) _claudeKeyController.text = claudeKey;
        if (hostedKey != null) _hostedKeyController.text = hostedKey;
      });
    }
  }

  @override
  void dispose() {
    _ollamaHostController.dispose();
    _ollamaPortController.dispose();
    _openAiKeyController.dispose();
    _claudeKeyController.dispose();
    _hostedKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierPriority =
        ref.watch(llmTierPriorityProvider).valueOrNull ??
        AnalysisTier.values.toList();
    final tierEnabled =
        ref.watch(llmTierEnabledProvider).valueOrNull ??
        {for (final t in AnalysisTier.values) t: true};

    return Scaffold(
      appBar: AppBar(title: const Text('AI Analysis')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Tier Priority
          _SectionHeader(title: 'Provider Priority', theme: theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Drag to reorder. The app tries each provider in order until one succeeds.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tierPriority.length,
            onReorder: (oldIndex, newIndex) {
              final list = List<AnalysisTier>.from(tierPriority);
              if (newIndex > oldIndex) newIndex--;
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              ref.read(llmTierPriorityProvider.notifier).setOrder(list);
            },
            itemBuilder: (context, index) {
              final tier = tierPriority[index];
              final enabled = tierEnabled[tier] ?? true;
              return ListTile(
                key: ValueKey(tier),
                leading: Icon(
                  _tierIcon(tier),
                  color: enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                title: Text(tier.label),
                subtitle: Text(_tierDescription(tier)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: enabled,
                      onChanged: (v) {
                        final map = Map<AnalysisTier, bool>.from(tierEnabled);
                        map[tier] = v;
                        ref
                            .read(llmTierEnabledProvider.notifier)
                            .setEnabled(map);
                      },
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 32),

          // Tier 1: On-Device
          _SectionHeader(title: 'On-Device ML (Tier 1)', theme: theme),
          const ListTile(
            leading: Icon(Icons.phone_android_outlined),
            title: Text('Always available'),
            subtitle: Text(
              'YOLO object detection + MobileNet classification. Works offline. '
              'Basic labels only (e.g., "television", "chair").',
            ),
          ),

          const Divider(height: 32),

          // Tier 2: Ollama
          _SectionHeader(title: 'Local LLM — Ollama (Tier 2)', theme: theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _ollamaHostController,
                    decoration: const InputDecoration(labelText: 'Host'),
                    onChanged: (v) =>
                        ref.read(ollamaHostProvider.notifier).setHost(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ollamaPortController,
                    decoration: const InputDecoration(labelText: 'Port'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref
                        .read(ollamaPortProvider.notifier)
                        .setPort(int.tryParse(v) ?? 11434),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Model',
                hintText: 'llava, kimi-k2, etc.',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showModelHelp(context),
                ),
              ),
              controller: TextEditingController(
                text: ref.watch(ollamaModelProvider).valueOrNull ?? 'llava',
              ),
              onChanged: (v) =>
                  ref.read(ollamaModelProvider.notifier).setModel(v),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _testingOllama ? null : _testOllamaConnection,
                  icon: _testingOllama
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find, size: 18),
                  label: const Text('Test Connection'),
                ),
                const SizedBox(width: 12),
                if (_ollamaConnected)
                  Chip(
                    avatar: Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    label: const Text('Connected'),
                  ),
              ],
            ),
          ),

          const Divider(height: 32),

          // Tier 3: Cloud APIs
          _SectionHeader(title: 'Cloud API (Tier 3)', theme: theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Use your own API key. You pay the provider directly.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _openAiKeyController,
              decoration: const InputDecoration(
                labelText: 'OpenAI API Key',
                hintText: 'sk-...',
                prefixIcon: Icon(Icons.key_outlined, size: 20),
              ),
              obscureText: true,
              onChanged: (v) =>
                  _secureStorage.write(key: 'openai_api_key', value: v),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _claudeKeyController,
              decoration: const InputDecoration(
                labelText: 'Claude API Key',
                hintText: 'sk-ant-...',
                prefixIcon: Icon(Icons.key_outlined, size: 20),
              ),
              obscureText: true,
              onChanged: (v) =>
                  _secureStorage.write(key: 'claude_api_key', value: v),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonalIcon(
              onPressed: _testingCloud ? null : _testCloudConnection,
              icon: _testingCloud
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_outlined, size: 18),
              label: const Text('Test Connection'),
            ),
          ),

          const Divider(height: 32),

          // Tier 4: Hosted
          _SectionHeader(title: 'Still Life Hosted (Tier 4)', theme: theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Our hosted AI analysis service. Pay per analysis.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _hostedKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sl-...',
                prefixIcon: Icon(Icons.key_outlined, size: 20),
              ),
              obscureText: true,
              onChanged: (v) =>
                  _secureStorage.write(key: 'hosted_api_key', value: v),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account creation coming soon')),
                );
              },
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Create Account'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  IconData _tierIcon(AnalysisTier tier) {
    return switch (tier) {
      AnalysisTier.onDevice => Icons.phone_android_outlined,
      AnalysisTier.localLlm => Icons.dns_outlined,
      AnalysisTier.cloudApi => Icons.cloud_outlined,
      AnalysisTier.hosted => Icons.rocket_launch_outlined,
    };
  }

  String _tierDescription(AnalysisTier tier) {
    return switch (tier) {
      AnalysisTier.onDevice => 'Free, offline, basic detection',
      AnalysisTier.localLlm => 'Free, your Ollama server, high quality',
      AnalysisTier.cloudApi => 'Your API key, highest quality',
      AnalysisTier.hosted => 'Pay per analysis, high quality',
    };
  }

  Future<void> _testOllamaConnection() async {
    setState(() {
      _testingOllama = true;
      _ollamaConnected = false;
    });

    // Ollama connectivity check is not yet wired to OllamaProvider.isAvailable().
    await Future<void>.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _testingOllama = false;
        _ollamaConnected = false; // Will be true once wired
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ollama connection check is not yet available'),
        ),
      );
    }
  }

  Future<void> _testCloudConnection() async {
    setState(() => _testingCloud = true);

    await Future<void>.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _testingCloud = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connection test will work once cloud provider is wired',
          ),
        ),
      );
    }
  }

  void _showModelHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ollama Vision Models'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommended models for item identification:'),
            SizedBox(height: 12),
            Text('llava — Good general-purpose vision model'),
            Text('kimi-k2 — Excellent at brand/model identification'),
            Text('llama3.2-vision — Fast, good accuracy'),
            SizedBox(height: 12),
            Text('Install via: ollama pull <model-name>'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

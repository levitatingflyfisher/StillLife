import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/providers/billing_providers.dart'
    show kHostedBaseUrl;
import '../../../../core/providers/cloud_api_settings.dart';
import '../../../../core/providers/repository_providers.dart'
    show onDeviceSupportProvider;
import '../../../../services/appraisal/appraiser_prompt.dart'
    show kAppraiserDefaultModel;
import '../../../../services/ml/analysis_provider.dart';
import '../../../../services/ml/cloud_api_provider.dart' show CloudApiType;
import '../../data/llm_connection_tester.dart';
import '../widgets/on_device_section.dart';

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
    if (saved == null || saved.isEmpty) return List.of(kDefaultTierPriority);
    final tiers = <AnalysisTier>[];
    for (final name in saved.split(',')) {
      try {
        tiers.add(AnalysisTier.values.byName(name));
      } catch (_) {
        // Skip unknown names from older app versions.
      }
    }
    // Ensure all tiers are represented (append any missing in default order
    // — quality-first, on-device last).
    for (final t in kDefaultTierPriority) {
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
    // The local-LLM tier defaults OFF: enabled, it probes (and would
    // POST photos/OCR text to) whatever answers on localhost:11434 —
    // on Android any app can bind that port, so an unconfigured install
    // must not fail open. Enabling it is a one-tap explicit opt-in here.
    final defaults = {
      for (final t in AnalysisTier.values) t: t != AnalysisTier.localLlm,
    };
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

/// Normalizes a typed/pasted Ollama host to a bare hostname or IP: the
/// base URL is assembled as `http://<host>:<port>`, so a pasted
/// `https://192.168.1.20/` must not produce `http://https://...`.
String normalizeOllamaHost(String host) {
  var h = host.trim();
  h = h.replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://'), '');
  while (h.endsWith('/')) {
    h = h.substring(0, h.length - 1);
  }
  return h;
}

/// True when [host] can only name a local-network destination: loopback,
/// the RFC1918 / link-local / IPv6-ULA ranges, `.local` mDNS names, or a
/// single-label hostname (resolvable only by local discovery).
///
/// The Ollama tier speaks plain HTTP, and the Android manifest now allows
/// non-localhost cleartext for exactly this feature — so the provider
/// wiring refuses to register the tier for any host that could route to
/// the public internet. Photo bytes and OCR text must never cross the
/// internet unencrypted, no matter what the user pastes here.
///
/// Deliberately avoids dart:io (this file ships to web).
bool isPrivateNetworkHost(String host) {
  var h = normalizeOllamaHost(host).toLowerCase();
  if (h.isEmpty) return false;
  if (h == 'localhost') return true;

  // IPv6, with or without brackets.
  var v6 = h;
  if (v6.startsWith('[') && v6.endsWith(']')) {
    v6 = v6.substring(1, v6.length - 1);
  }
  if (v6.contains(':')) {
    if (v6 == '::1') return true;
    // fe80::/10 link-local: fe8x, fe9x, feax, febx.
    if (RegExp(r'^fe[89ab]').hasMatch(v6)) return true;
    // fc00::/7 unique-local: fcxx, fdxx.
    if (v6.startsWith('fc') || v6.startsWith('fd')) return true;
    return false;
  }

  // IPv4.
  final octets = h.split('.');
  if (octets.length == 4 &&
      octets.every((o) => o.isNotEmpty && int.tryParse(o) != null)) {
    final a = int.parse(octets[0]);
    final b = int.parse(octets[1]);
    if (a == 127 || a == 10) return true;
    if (a == 192 && b == 168) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    if (a == 169 && b == 254) return true;
    return false;
  }

  // Hostnames: `.local` is mDNS by definition; a single-label name has no
  // public DNS meaning. Anything else could resolve on the internet.
  if (h.endsWith('.local')) return true;
  return !h.contains('.');
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
    final normalized = normalizeOllamaHost(host);
    await _secureStorage.write(key: _kOllamaHostKey, value: normalized);
    state = AsyncData(normalized);
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

/// Persisted cloud provider type (tier 3). Writes the `cloud_api_type`
/// key the core's [cloudApiConfigProvider] consumes; when nothing is
/// stored yet the type is inferred the same way the core infers it, so
/// the UI and the analysis tier never disagree.
final cloudApiTypeSettingProvider =
    AsyncNotifierProvider<CloudApiTypeSettingNotifier, CloudApiType>(
      CloudApiTypeSettingNotifier.new,
    );

class CloudApiTypeSettingNotifier extends AsyncNotifier<CloudApiType> {
  @override
  Future<CloudApiType> build() async {
    final storage = ref.watch(secureStorageProvider);
    return switch (await storage.read(key: kCloudApiTypeStorageKey)) {
      'claude' => CloudApiType.claude,
      'openai' => CloudApiType.openai,
      _ =>
        ((await storage.read(key: kClaudeApiKeyStorageKey)) ?? '').isNotEmpty
            ? CloudApiType.claude
            : CloudApiType.openai,
    };
  }

  Future<void> setType(CloudApiType type) async {
    await ref
        .read(secureStorageProvider)
        .write(key: kCloudApiTypeStorageKey, value: type.name);
    state = AsyncData(type);
    ref.invalidate(cloudApiConfigProvider);
  }
}

/// Claude API key (tier 3). Persists to the `claude_api_key` slot the
/// core reads and refreshes the tier's config on change.
final claudeApiKeySettingProvider =
    AsyncNotifierProvider<ClaudeApiKeySettingNotifier, String>(
      ClaudeApiKeySettingNotifier.new,
    );

class ClaudeApiKeySettingNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final storage = ref.watch(secureStorageProvider);
    return (await storage.read(key: kClaudeApiKeyStorageKey)) ?? '';
  }

  Future<void> setKey(String key) async {
    // Trimmed: a pasted trailing CR/space would poison the x-api-key
    // header at runtime while the trimmed Test Connection passes.
    final trimmed = key.trim();
    await ref
        .read(secureStorageProvider)
        .write(key: kClaudeApiKeyStorageKey, value: trimmed);
    state = AsyncData(trimmed);
    ref.invalidate(cloudApiConfigProvider);
  }
}

/// Anthropic model id the Appraiser uses for market-value estimates.
/// Follows the Ollama-model persistence pattern; blank falls back to the
/// default alias so a cleared field never leaves a dead model id behind.
final appraiserModelSettingProvider =
    AsyncNotifierProvider<AppraiserModelSettingNotifier, String>(
      AppraiserModelSettingNotifier.new,
    );

class AppraiserModelSettingNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final storage = ref.watch(secureStorageProvider);
    final saved = await storage.read(key: kAppraiserModelStorageKey);
    return (saved == null || saved.trim().isEmpty)
        ? kAppraiserDefaultModel
        : saved;
  }

  Future<void> setModel(String model) async {
    final trimmed = model.trim();
    await ref
        .read(secureStorageProvider)
        .write(key: kAppraiserModelStorageKey, value: trimmed);
    state = AsyncData(trimmed.isEmpty ? kAppraiserDefaultModel : trimmed);
  }
}

/// Base URL of the OpenAI-compatible endpoint (tier 3).
final openAiCompatBaseUrlProvider =
    AsyncNotifierProvider<OpenAiCompatBaseUrlNotifier, String>(
      OpenAiCompatBaseUrlNotifier.new,
    );

class OpenAiCompatBaseUrlNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final storage = ref.watch(secureStorageProvider);
    final saved = await storage.read(key: kOpenAiCompatBaseUrlStorageKey);
    return (saved == null || saved.isEmpty)
        ? kOpenAiCompatDefaultBaseUrl
        : saved;
  }

  Future<void> setBaseUrl(String baseUrl) async {
    final trimmed = baseUrl.trim();
    await ref
        .read(secureStorageProvider)
        .write(key: kOpenAiCompatBaseUrlStorageKey, value: trimmed);
    state = AsyncData(trimmed);
    ref.invalidate(cloudApiConfigProvider);
  }
}

/// API key for the OpenAI-compatible endpoint (tier 3). Prefills from
/// the legacy `openai_api_key` slot older builds wrote so an existing
/// key is never silently dropped.
final openAiCompatApiKeyProvider =
    AsyncNotifierProvider<OpenAiCompatApiKeyNotifier, String>(
      OpenAiCompatApiKeyNotifier.new,
    );

class OpenAiCompatApiKeyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final storage = ref.watch(secureStorageProvider);
    final saved = await storage.read(key: kOpenAiCompatApiKeyStorageKey);
    if (saved != null && saved.isNotEmpty) return saved;
    return (await storage.read(key: kLegacyOpenAiApiKeyStorageKey)) ?? '';
  }

  Future<void> setKey(String key) async {
    final trimmed = key.trim();
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: kOpenAiCompatApiKeyStorageKey, value: trimmed);
    // The user has now expressed intent for this slot; the legacy slot
    // must be deleted, or the config loader's empty-means-fall-back rule
    // would silently resurrect an old key the user believes revoked.
    await storage.delete(key: kLegacyOpenAiApiKeyStorageKey);
    state = AsyncData(trimmed);
    ref.invalidate(cloudApiConfigProvider);
  }
}

/// Model name sent to the OpenAI-compatible endpoint (tier 3).
final openAiCompatModelProvider =
    AsyncNotifierProvider<OpenAiCompatModelNotifier, String>(
      OpenAiCompatModelNotifier.new,
    );

class OpenAiCompatModelNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final storage = ref.watch(secureStorageProvider);
    final saved = await storage.read(key: kOpenAiCompatModelStorageKey);
    return (saved == null || saved.isEmpty) ? kOpenAiCompatDefaultModel : saved;
  }

  Future<void> setModel(String model) async {
    final trimmed = model.trim();
    await ref
        .read(secureStorageProvider)
        .write(key: kOpenAiCompatModelStorageKey, value: trimmed);
    state = AsyncData(trimmed);
    ref.invalidate(cloudApiConfigProvider);
  }
}

class LlmSettingsScreen extends ConsumerStatefulWidget {
  const LlmSettingsScreen({super.key});

  @override
  ConsumerState<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends ConsumerState<LlmSettingsScreen> {
  final _ollamaHostController = TextEditingController();
  final _ollamaPortController = TextEditingController();
  final _compatBaseUrlController = TextEditingController();
  final _compatKeyController = TextEditingController();
  final _compatModelController = TextEditingController();
  final _claudeKeyController = TextEditingController();
  final _appraiserModelController = TextEditingController();

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
    final claudeKey = await ref.read(claudeApiKeySettingProvider.future);
    final compatBaseUrl = await ref.read(openAiCompatBaseUrlProvider.future);
    final compatKey = await ref.read(openAiCompatApiKeyProvider.future);
    final compatModel = await ref.read(openAiCompatModelProvider.future);
    final appraiserModel = await ref.read(
      appraiserModelSettingProvider.future,
    );
    if (mounted) {
      setState(() {
        _claudeKeyController.text = claudeKey;
        _compatBaseUrlController.text = compatBaseUrl;
        _compatKeyController.text = compatKey;
        _compatModelController.text = compatModel;
        _appraiserModelController.text = appraiserModel;
      });
    }
  }

  @override
  void dispose() {
    _ollamaHostController.dispose();
    _ollamaPortController.dispose();
    _compatBaseUrlController.dispose();
    _compatKeyController.dispose();
    _compatModelController.dispose();
    _claudeKeyController.dispose();
    _appraiserModelController.dispose();
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
        {for (final t in AnalysisTier.values) t: t != AnalysisTier.localLlm};
    final cloudType =
        ref.watch(cloudApiTypeSettingProvider).valueOrNull ??
        CloudApiType.openai;

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
              // On-device is real on Android (bundled labeler + optional
              // downloaded models) and unsupported elsewhere; the hosted
              // tier fails closed when no HOSTED_BASE_URL is compiled in.
              // Unavailable tiers pin the toggle off and disabled, because
              // a live switch would promise something the tier can't do
              // in this build.
              final available = switch (tier) {
                AnalysisTier.onDevice =>
                  ref.watch(onDeviceSupportProvider).supported,
                AnalysisTier.hosted => kHostedBaseUrl.isNotEmpty,
                _ => true,
              };
              final enabled = available && (tierEnabled[tier] ?? true);
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
                      onChanged: available
                          ? (v) {
                              final map = Map<AnalysisTier, bool>.from(
                                tierEnabled,
                              );
                              map[tier] = v;
                              ref
                                  .read(llmTierEnabledProvider.notifier)
                                  .setEnabled(map);
                            }
                          : null,
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 32),

          // Tier 1: On-Device — real on Android (bundled labeler +
          // optional downloaded VLM + Gemini Nano where AICore exists).
          _SectionHeader(title: 'On-Device ML (Tier 1)', theme: theme),
          const OnDeviceSection(),

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
                    decoration: const InputDecoration(
                      labelText: 'Host',
                      helperText:
                          'Local network only (192.168.x, 10.x, name.local) — '
                          'plain-HTTP Ollama never leaves your LAN',
                      helperMaxLines: 2,
                    ),
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
                hintText: 'llava, qwen2.5vl, etc.',
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
            child: SegmentedButton<CloudApiType>(
              segments: const [
                ButtonSegment(
                  value: CloudApiType.claude,
                  label: Text('Anthropic'),
                ),
                ButtonSegment(
                  value: CloudApiType.openai,
                  label: Text('OpenAI-compatible'),
                ),
              ],
              selected: {cloudType},
              onSelectionChanged: (selection) => ref
                  .read(cloudApiTypeSettingProvider.notifier)
                  .setType(selection.first),
            ),
          ),
          const SizedBox(height: 12),
          if (cloudType == CloudApiType.claude) ...[
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
                    ref.read(claudeApiKeySettingProvider.notifier).setKey(v),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _appraiserModelController,
                decoration: const InputDecoration(
                  labelText: 'Appraiser model',
                  hintText: kAppraiserDefaultModel,
                  helperText:
                      'Anthropic model id used for market-value estimates',
                  prefixIcon: Icon(Icons.smart_toy_outlined, size: 20),
                ),
                onChanged: (v) => ref
                    .read(appraiserModelSettingProvider.notifier)
                    .setModel(v),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _compatBaseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.openai.com/v1',
                  prefixIcon: Icon(Icons.link_outlined, size: 20),
                ),
                keyboardType: TextInputType.url,
                onChanged: (v) => ref
                    .read(openAiCompatBaseUrlProvider.notifier)
                    .setBaseUrl(v),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _compatKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-... (empty for local servers)',
                  prefixIcon: Icon(Icons.key_outlined, size: 20),
                ),
                obscureText: true,
                onChanged: (v) =>
                    ref.read(openAiCompatApiKeyProvider.notifier).setKey(v),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _compatModelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'gpt-4o, llava, ...',
                  prefixIcon: Icon(Icons.smart_toy_outlined, size: 20),
                ),
                onChanged: (v) =>
                    ref.read(openAiCompatModelProvider.notifier).setModel(v),
              ),
            ),
          ],
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

          // Tier 4: Hosted. The tier is scaffolding: kHostedBaseUrl
          // defaults to empty (fail-closed) and bearers are only ever
          // issued by the billing service's activation flow — so there
          // is nothing to type here, and the section says so.
          _SectionHeader(title: 'Still Life Hosted (Tier 4)', theme: theme),
          if (kHostedBaseUrl.isEmpty)
            const ListTile(
              leading: Icon(Icons.cloud_off_outlined),
              title: Text('Not configured'),
              subtitle: Text(
                'No hosted backend is set up for this build. Operators can '
                'enable one with --dart-define=HOSTED_BASE_URL=https://...',
              ),
            )
          else
            const ListTile(
              leading: Icon(Icons.rocket_launch_outlined),
              title: Text(kHostedBaseUrl),
              subtitle: Text(
                'Access keys are issued through account activation '
                '(Settings → Pro status), not entered here.',
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
      AnalysisTier.onDevice => 'Not yet available',
      AnalysisTier.localLlm => 'Free, your Ollama server, high quality',
      AnalysisTier.cloudApi => 'Your API key, highest quality',
      AnalysisTier.hosted => kHostedBaseUrl.isEmpty
          ? 'Not configured in this build'
          : 'Pay per analysis, high quality',
    };
  }

  Future<void> _testOllamaConnection() async {
    setState(() {
      _testingOllama = true;
      _ollamaConnected = false;
    });

    final host = normalizeOllamaHost(_ollamaHostController.text);
    final result = await ref
        .read(llmConnectionTesterProvider)
        .testOllama(
          host: host.isEmpty ? 'localhost' : host,
          port: int.tryParse(_ollamaPortController.text.trim()) ?? 11434,
        );

    if (!mounted) return;
    setState(() {
      _testingOllama = false;
      _ollamaConnected = result.ok;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _testCloudConnection() async {
    setState(() => _testingCloud = true);

    final apiType =
        ref.read(cloudApiTypeSettingProvider).valueOrNull ??
        CloudApiType.openai;
    final result = await ref
        .read(llmConnectionTesterProvider)
        .testCloud(
          apiType: apiType,
          apiKey: apiType == CloudApiType.claude
              ? _claudeKeyController.text.trim()
              : _compatKeyController.text.trim(),
          openAiBaseUrl: _compatBaseUrlController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _testingCloud = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
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
            Text('Photo analysis needs a vision-capable model:'),
            SizedBox(height: 12),
            Text('llava — solid general-purpose vision'),
            Text('llama3.2-vision — fast, good accuracy'),
            Text('qwen2.5vl — strong at labels and text in photos'),
            SizedBox(height: 12),
            Text('Voice add only needs text — llama3.1 works well.'),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/providers/cloud_api_settings.dart';
import 'package:still_life/features/settings/data/llm_connection_tester.dart';
import 'package:still_life/features/settings/presentation/screens/llm_settings_screen.dart';
import 'package:still_life/services/ml/cloud_api_provider.dart'
    show CloudApiType;

import '../../../../mocks/fake_secure_storage_channel.dart';

/// Canned-result stand-in for the real prober so widget tests can drive
/// both button outcomes without HTTP.
class _FakeConnectionTester implements LlmConnectionTester {
  _FakeConnectionTester({required this.ollamaResult, required this.cloudResult});

  ConnectionTestResult ollamaResult;
  ConnectionTestResult cloudResult;

  String? lastHost;
  int? lastPort;
  CloudApiType? lastApiType;
  String? lastApiKey;
  String? lastBaseUrl;

  @override
  Future<ConnectionTestResult> testOllama({
    required String host,
    required int port,
  }) async {
    lastHost = host;
    lastPort = port;
    return ollamaResult;
  }

  @override
  Future<ConnectionTestResult> testCloud({
    required CloudApiType apiType,
    required String apiKey,
    String openAiBaseUrl = '',
  }) async {
    lastApiType = apiType;
    lastApiKey = apiKey;
    lastBaseUrl = openAiBaseUrl;
    return cloudResult;
  }
}

void main() {
  late FakeSecureStorageChannel fake;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    fake = FakeSecureStorageChannel()..install();
  });

  tearDown(() {
    fake.uninstall();
  });

  Widget buildSubject({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: LlmSettingsScreen()),
    );
  }

  /// The settings list is long; give the test surface enough height that
  /// every section renders without scrolling gymnastics.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('cloud API section', () {
    testWidgets('shows the OpenAI-compatible trio by default — base URL, '
        'API key, and model', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Base URL'), findsOneWidget);
      expect(find.text('sk-... (empty for local servers)'), findsOneWidget);
      // 'Model' appears for both Ollama and the compat trio.
      expect(find.text('Model'), findsNWidgets(2));
      // The dead single-purpose key field is gone.
      expect(find.text('OpenAI API Key'), findsNothing);
    });

    testWidgets('selecting Anthropic persists cloud_api_type and swaps in '
        'the Claude key field', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Anthropic'));
      await tester.pumpAndSettle();

      expect(fake.values[kCloudApiTypeStorageKey], 'claude');
      expect(find.text('Claude API Key'), findsOneWidget);
      expect(find.text('Base URL'), findsNothing);
    });

    testWidgets('editing the compat base URL persists to '
        'openai_compat_base_url', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Base URL'),
        'http://localhost:8080/v1',
      );
      await tester.pumpAndSettle();

      expect(
        fake.values[kOpenAiCompatBaseUrlStorageKey],
        'http://localhost:8080/v1',
      );
    });

    testWidgets('Anthropic section offers the appraiser model id next to '
        'the key field, prefilled with the default', (tester) async {
      useTallSurface(tester);
      fake.values[kCloudApiTypeStorageKey] = 'claude';
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Appraiser model'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Appraiser model'),
      );
      expect(field.controller?.text, 'claude-sonnet-4-6');
      // A model-id helper hint so users know what belongs here.
      expect(find.textContaining('model id'), findsOneWidget);
    });

    testWidgets('editing the appraiser model persists to appraiser_model_v1',
        (tester) async {
      useTallSurface(tester);
      fake.values[kCloudApiTypeStorageKey] = 'claude';
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Appraiser model'),
        'claude-opus-4-6',
      );
      await tester.pumpAndSettle();

      expect(fake.values[kAppraiserModelStorageKey], 'claude-opus-4-6');
    });

    testWidgets('stored claude type is restored on open', (tester) async {
      useTallSurface(tester);
      fake.values[kCloudApiTypeStorageKey] = 'claude';
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Claude API Key'), findsOneWidget);
      expect(find.text('Base URL'), findsNothing);
      expect(
        tester
            .widget<SegmentedButton<CloudApiType>>(
              find.byType(SegmentedButton<CloudApiType>),
            )
            .selected,
        {CloudApiType.claude},
      );
    });
  });

  group('model help dialog', () {
    testWidgets('recommends vision-capable models for this vision task — '
        'text-only kimi-k2 is gone', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      Finder inDialog(String text) => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining(text),
      );

      expect(find.textContaining('kimi-k2'), findsNothing);
      expect(inDialog('llava'), findsOneWidget);
      expect(inDialog('llama3.2-vision'), findsOneWidget);
      expect(inDialog('qwen2.5vl'), findsOneWidget);
      // One text model for the voice-transcript extraction path.
      expect(inDialog('llama3.1'), findsOneWidget);
    });
  });

  group('on-device tier honesty', () {
    testWidgets('no phantom YOLO/MobileNet copy — the tier says it is not '
        'yet available', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('YOLO'), findsNothing);
      expect(find.text('Always available'), findsNothing);
      // On this test host there is no on-device runtime; the section says
      // so instead of promising phantom inference.
      expect(
        find.textContaining('Not available on this platform'),
        findsWidgets,
      );
    });

    testWidgets('the on-device priority toggle is off and disabled where '
        'the platform has no on-device runtime (this test host) — on '
        'Android the same switch is live', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Default priority order is quality-first: localLlm, cloudApi,
      // hosted, onDevice — the on-device floor sits LAST.
      final onDeviceSwitch = tester.widget<Switch>(find.byType(Switch).at(3));
      expect(onDeviceSwitch.onChanged, isNull);
      expect(onDeviceSwitch.value, isFalse);
    });

    testWidgets('the hosted priority toggle is pinned off in a default '
        'build — kHostedBaseUrl is empty, so a live switch would promise '
        'something the tier can never do', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Default priority order: localLlm, cloudApi, hosted, onDevice.
      final hostedSwitch =
          tester.widget<Switch>(find.byType(Switch).at(2));
      expect(hostedSwitch.onChanged, isNull,
          reason: 'the tier fails closed on the empty base URL; the '
              'toggle must not advertise a pay-per-analysis option that '
              'cannot exist in this build');
      expect(hostedSwitch.value, isFalse);
      expect(find.text('Pay per analysis, high quality'), findsNothing,
          reason: 'sales copy for an unconfigurable tier is dishonest');
    });
  });

  group('hosted section', () {
    testWidgets('no Create Account button and no dead manual key field — '
        'unconfigured hosted tier says so honestly', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // The coming-soon button and the write-only key field are gone.
      expect(find.text('Create Account'), findsNothing);
      expect(find.text('sl-...'), findsNothing);

      // kHostedBaseUrl defaults to empty (fail-closed), so the section
      // must say "Not configured" and point at the dart-define.
      expect(find.text('Not configured'), findsOneWidget);
      expect(find.textContaining('HOSTED_BASE_URL'), findsOneWidget);
    });
  });

  group('test connection buttons', () {
    testWidgets('Ollama button probes the configured host/port and shows '
        'the real result', (tester) async {
      useTallSurface(tester);
      fake.values['ollama_host_v1'] = '192.168.1.9';
      fake.values['ollama_port_v1'] = '11500';
      final probe = _FakeConnectionTester(
        ollamaResult: const ConnectionTestResult(
          ok: true,
          message: 'Connected — 2 models: llava:latest, qwen2.5vl:7b',
          models: ['llava:latest', 'qwen2.5vl:7b'],
        ),
        cloudResult: const ConnectionTestResult(ok: false, message: 'unused'),
      );
      await tester.pumpWidget(
        buildSubject(
          overrides: [llmConnectionTesterProvider.overrideWithValue(probe)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Connection').first);
      await tester.pumpAndSettle();

      expect(probe.lastHost, '192.168.1.9');
      expect(probe.lastPort, 11500);
      expect(
        find.text('Connected — 2 models: llava:latest, qwen2.5vl:7b'),
        findsOneWidget,
      );
      expect(find.text('Connected'), findsOneWidget); // the chip
      expect(find.text('Ollama connection check is not yet available'),
          findsNothing);
    });

    testWidgets('Ollama failure shows the actual error and no Connected '
        'chip', (tester) async {
      useTallSurface(tester);
      final probe = _FakeConnectionTester(
        ollamaResult: const ConnectionTestResult(
          ok: false,
          message: 'Ollama unreachable: connection refused',
        ),
        cloudResult: const ConnectionTestResult(ok: false, message: 'unused'),
      );
      await tester.pumpWidget(
        buildSubject(
          overrides: [llmConnectionTesterProvider.overrideWithValue(probe)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Connection').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Ollama unreachable: connection refused'),
        findsOneWidget,
      );
      expect(find.text('Connected'), findsNothing);
    });

    testWidgets('cloud button probes the selected type with the entered '
        'credentials and shows the real result', (tester) async {
      useTallSurface(tester);
      fake.values[kCloudApiTypeStorageKey] = 'openai';
      fake.values[kOpenAiCompatBaseUrlStorageKey] = 'http://localhost:8080/v1';
      fake.values[kOpenAiCompatApiKeyStorageKey] = 'sk-compat';
      final probe = _FakeConnectionTester(
        ollamaResult: const ConnectionTestResult(ok: false, message: 'unused'),
        cloudResult: const ConnectionTestResult(
          ok: false,
          message: 'Connection failed: HTTP 401 — invalid key',
        ),
      );
      await tester.pumpWidget(
        buildSubject(
          overrides: [llmConnectionTesterProvider.overrideWithValue(probe)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Connection').last);
      await tester.pumpAndSettle();

      expect(probe.lastApiType, CloudApiType.openai);
      expect(probe.lastApiKey, 'sk-compat');
      expect(probe.lastBaseUrl, 'http://localhost:8080/v1');
      expect(
        find.text('Connection failed: HTTP 401 — invalid key'),
        findsOneWidget,
      );
      expect(
        find.text('Connection test will work once cloud provider is wired'),
        findsNothing,
      );
    });
  });
}

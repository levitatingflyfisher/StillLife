import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/settings/presentation/widgets/on_device_section.dart';
import 'package:still_life/services/ml/on_device/model_download_types.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/nano_engine.dart';
import 'package:still_life/services/ml/on_device/on_device_models_api.dart';
import 'package:still_life/services/ml/on_device/on_device_support_types.dart';

class _FakeModelsApi implements OnDeviceModelsApi {
  final Set<String> installed;
  final List<String> downloadCalls = [];
  final List<String> deleteCalls = [];
  Completer<void>? gate;

  _FakeModelsApi({Set<String>? installed}) : installed = installed ?? {};

  @override
  Future<bool> isDownloaded(OnDeviceModel model) async =>
      installed.contains(model.id);

  @override
  Future<void> download(
    OnDeviceModel model, {
    void Function(double fraction)? onProgress,
    ModelDownloadToken? token,
  }) async {
    downloadCalls.add(model.id);
    onProgress?.call(0.42);
    if (gate != null) await gate!.future;
    installed.add(model.id);
  }

  @override
  Future<void> delete(OnDeviceModel model) async {
    deleteCalls.add(model.id);
    installed.remove(model.id);
  }
}

class _FakeNano implements NanoGateway {
  NanoStatus status;
  bool setupRequested = false;
  _FakeNano(this.status);

  @override
  Future<NanoStatus> checkStatus() async => status;

  @override
  Future<void> requestSetup() async {
    setupRequested = true;
  }

  @override
  Future<String> promptWithImage({
    required String prompt,
    required Uint8List imageBytes,
  }) async => '{}';
}

Widget _app(OnDeviceSupport support) => ProviderScope(
  overrides: [onDeviceSupportProvider.overrideWithValue(support)],
  child: const MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: OnDeviceSection())),
  ),
);

void main() {
  final big = kOnDeviceModels.first;

  testWidgets('unsupported platform explains itself and offers nothing',
      (tester) async {
    await tester.pumpWidget(
      _app(const OnDeviceSupport(supported: false, engines: [])),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Android app'), findsOneWidget);
    expect(find.text('Download'), findsNothing);
  });

  testWidgets('supported: labeler is Ready, models list sizes, Nano shows '
      'device support state', (tester) async {
    await tester.pumpWidget(
      _app(OnDeviceSupport(
        supported: true,
        engines: const [],
        models: _FakeModelsApi(),
        nano: _FakeNano(NanoStatus.unsupported),
      )),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Instant labeler'), findsOneWidget);
    expect(find.textContaining('Ready'), findsWidgets);
    expect(find.textContaining('SmolVLM2 2.2B'), findsOneWidget);
    expect(find.textContaining('1.7 GB'), findsOneWidget);
    expect(find.textContaining('546 MB'), findsOneWidget);
    expect(find.textContaining('Not supported on this device'), findsOneWidget);
  });

  testWidgets('Nano downloadable → Set up tap requests provisioning',
      (tester) async {
    final nano = _FakeNano(NanoStatus.downloadable);
    await tester.pumpWidget(
      _app(OnDeviceSupport(
        supported: true,
        engines: const [],
        models: _FakeModelsApi(),
        nano: nano,
      )),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set up'));
    await tester.pumpAndSettle();

    expect(nano.setupRequested, isTrue);
  });

  testWidgets('download flow: confirm dialog (size + RAM note) → progress '
      '→ Downloaded with Delete', (tester) async {
    final api = _FakeModelsApi()..gate = Completer();
    await tester.pumpWidget(
      _app(OnDeviceSupport(
        supported: true,
        engines: const [],
        models: api,
        nano: _FakeNano(NanoStatus.unsupported),
      )),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Download').first);
    await tester.pumpAndSettle();

    // Confirm dialog carries the informed-consent copy.
    expect(find.textContaining('1.7 GB'), findsWidgets);
    expect(find.textContaining('RAM'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Download').last);
    // Settle the dialog dismissal; the download itself stays gated, and
    // the determinate progress bar doesn't animate.
    await tester.pumpAndSettle();

    expect(api.downloadCalls, [big.id]);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    api.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.textContaining('Downloaded'), findsWidgets);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('delete flow asks for confirmation before removing',
      (tester) async {
    final api = _FakeModelsApi(installed: {big.id});
    await tester.pumpWidget(
      _app(OnDeviceSupport(
        supported: true,
        engines: const [],
        models: api,
        nano: _FakeNano(NanoStatus.unsupported),
      )),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(api.deleteCalls, isEmpty, reason: 'nothing deleted before confirm');

    await tester.tap(find.text('Delete model'));
    await tester.pumpAndSettle();

    expect(api.deleteCalls, [big.id]);
    expect(find.widgetWithText(FilledButton, 'Download'), findsWidgets);
  });
}

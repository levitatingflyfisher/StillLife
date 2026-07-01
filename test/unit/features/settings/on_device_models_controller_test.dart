import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/settings/presentation/controllers/on_device_models_controller.dart';
import 'package:still_life/services/ml/on_device/model_download_types.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/on_device_models_api.dart';
import 'package:still_life/services/ml/on_device/on_device_support_types.dart';

class _FakeModelsApi implements OnDeviceModelsApi {
  final Set<String> installed;
  final List<String> downloaded = [];
  final List<String> deleted = [];

  /// Script for download(): emits these progress values, then completes —
  /// or throws [failure] / honours a cancelled token.
  List<double> progressScript;
  Object? failure;

  _FakeModelsApi({Set<String>? installed, this.progressScript = const [0.5]})
    : installed = installed ?? {};

  @override
  Future<bool> isDownloaded(OnDeviceModel model) async =>
      installed.contains(model.id);

  @override
  Future<void> download(
    OnDeviceModel model, {
    void Function(double fraction)? onProgress,
    ModelDownloadToken? token,
  }) async {
    downloaded.add(model.id);
    for (final p in progressScript) {
      await Future<void>.delayed(Duration.zero);
      if (token?.isCancelled ?? false) throw ModelDownloadCancelled();
      onProgress?.call(p);
    }
    if (failure != null) throw failure!;
    installed.add(model.id);
  }

  @override
  Future<void> delete(OnDeviceModel model) async {
    deleted.add(model.id);
    installed.remove(model.id);
  }
}

ProviderContainer _container(_FakeModelsApi api) {
  final container = ProviderContainer(
    overrides: [
      onDeviceSupportProvider.overrideWithValue(
        OnDeviceSupport(supported: true, engines: const [], models: api),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final big = kOnDeviceModels.first;
  final lite = kOnDeviceModels.last;

  test('build reports Installed vs NotDownloaded per registry model',
      () async {
    final container = _container(_FakeModelsApi(installed: {lite.id}));

    final statuses = await container.read(
      onDeviceModelsControllerProvider.future,
    );

    expect(statuses[big.id], isA<ModelNotDownloaded>());
    expect(statuses[lite.id], isA<ModelInstalled>());
  });

  test('download drives NotDownloaded → Downloading(progress) → Installed',
      () async {
    final api = _FakeModelsApi(progressScript: [0.25, 0.9]);
    final container = _container(api);
    await container.read(onDeviceModelsControllerProvider.future);

    final seen = <ModelStatus>[];
    container.listen(onDeviceModelsControllerProvider, (_, next) {
      final s = next.valueOrNull?[big.id];
      if (s != null) seen.add(s);
    });

    await container
        .read(onDeviceModelsControllerProvider.notifier)
        .download(big);

    expect(api.downloaded, [big.id]);
    expect(seen.whereType<ModelDownloading>().map((s) => s.progress),
        containsAllInOrder([0.25, 0.9]));
    expect(seen.last, isA<ModelInstalled>());
  });

  test('a failed download surfaces ModelDownloadFailed with the message',
      () async {
    final api = _FakeModelsApi()
      ..failure = const ModelDownloadException('sha256 mismatch');
    final container = _container(api);
    await container.read(onDeviceModelsControllerProvider.future);

    await container
        .read(onDeviceModelsControllerProvider.notifier)
        .download(big);

    final status = container
        .read(onDeviceModelsControllerProvider)
        .value![big.id];
    expect(status, isA<ModelDownloadFailed>());
    expect((status as ModelDownloadFailed).message, contains('sha256'));
  });

  test('cancel flips the token and the status returns to NotDownloaded',
      () async {
    final api = _FakeModelsApi(progressScript: [0.1, 0.2, 0.3]);
    final container = _container(api);
    await container.read(onDeviceModelsControllerProvider.future);
    final notifier = container.read(onDeviceModelsControllerProvider.notifier);

    final download = notifier.download(big);
    await Future<void>.delayed(Duration.zero);
    notifier.cancel(big);
    await download;

    final status = container
        .read(onDeviceModelsControllerProvider)
        .value![big.id];
    expect(status, isA<ModelNotDownloaded>(),
        reason: 'cancellation is not an error state');
    expect(api.installed, isNot(contains(big.id)));
  });

  test('delete calls the api and returns the model to NotDownloaded',
      () async {
    final api = _FakeModelsApi(installed: {big.id});
    final container = _container(api);
    await container.read(onDeviceModelsControllerProvider.future);

    await container
        .read(onDeviceModelsControllerProvider.notifier)
        .delete(big);

    expect(api.deleted, [big.id]);
    expect(
      container.read(onDeviceModelsControllerProvider).value![big.id],
      isA<ModelNotDownloaded>(),
    );
  });

  test('unsupported platform (no models api) yields an empty status map',
      () async {
    final container = ProviderContainer(
      overrides: [
        onDeviceSupportProvider.overrideWithValue(
          const OnDeviceSupport(supported: false, engines: []),
        ),
      ],
    );
    addTearDown(container.dispose);

    final statuses = await container.read(
      onDeviceModelsControllerProvider.future,
    );
    expect(statuses, isEmpty);
  });
}

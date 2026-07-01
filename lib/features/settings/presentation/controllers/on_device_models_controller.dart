import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/services/ml/on_device/model_download_types.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/nano_engine.dart';

/// UI-facing status of one downloadable on-device model.
sealed class ModelStatus {
  const ModelStatus();
}

class ModelNotDownloaded extends ModelStatus {
  const ModelNotDownloaded();
}

class ModelDownloading extends ModelStatus {
  final double progress; // 0..1
  const ModelDownloading(this.progress);
}

class ModelInstalled extends ModelStatus {
  const ModelInstalled();
}

class ModelDownloadFailed extends ModelStatus {
  final String message;
  const ModelDownloadFailed(this.message);
}

/// Download/installed state per registry model id, driving the settings
/// section. Downloads run through the platform's [OnDeviceModelsApi]
/// (verified, fail-closed); cancellation returns the model to
/// NotDownloaded — it is a user choice, not an error.
final onDeviceModelsControllerProvider =
    AsyncNotifierProvider<OnDeviceModelsController, Map<String, ModelStatus>>(
      OnDeviceModelsController.new,
    );

class OnDeviceModelsController
    extends AsyncNotifier<Map<String, ModelStatus>> {
  final Map<String, ModelDownloadToken> _tokens = {};

  @override
  Future<Map<String, ModelStatus>> build() async {
    final api = ref.watch(onDeviceSupportProvider).models;
    if (api == null) return const {};
    return {
      for (final model in kOnDeviceModels)
        model.id: await api.isDownloaded(model)
            ? const ModelInstalled()
            : const ModelNotDownloaded(),
    };
  }

  void _set(String id, ModelStatus status) {
    final current = state.valueOrNull ?? const <String, ModelStatus>{};
    state = AsyncData({...current, id: status});
  }

  /// Starts a user-initiated download. Progress updates are throttled to
  /// whole-percent steps — a GB-scale file reports thousands of chunks
  /// and the UI needs at most 100 repaints.
  Future<void> download(OnDeviceModel model) async {
    final api = ref.read(onDeviceSupportProvider).models;
    if (api == null) return;

    final token = ModelDownloadToken();
    _tokens[model.id] = token;
    _set(model.id, const ModelDownloading(0));
    var lastShown = 0.0;

    try {
      await api.download(
        model,
        token: token,
        onProgress: (p) {
          if (p - lastShown >= 0.01 || p >= 1.0) {
            lastShown = p;
            _set(model.id, ModelDownloading(p));
          }
        },
      );
      _set(model.id, const ModelInstalled());
    } on ModelDownloadCancelled {
      _set(model.id, const ModelNotDownloaded());
    } catch (e) {
      _set(
        model.id,
        ModelDownloadFailed(
          e is ModelDownloadException ? e.message : '$e',
        ),
      );
    } finally {
      _tokens.remove(model.id);
    }
  }

  /// Cancels an in-flight download of [model] (no-op otherwise).
  void cancel(OnDeviceModel model) => _tokens[model.id]?.cancel();

  Future<void> delete(OnDeviceModel model) async {
    final api = ref.read(onDeviceSupportProvider).models;
    if (api == null) return;
    await api.delete(model);
    _set(model.id, const ModelNotDownloaded());
  }
}

/// Gemini Nano feature status, or null where the platform has no AICore
/// surface at all (web/desktop).
final nanoStatusProvider = FutureProvider<NanoStatus?>((ref) async {
  final nano = ref.watch(onDeviceSupportProvider).nano;
  if (nano == null) return null;
  return nano.checkStatus();
});

import 'package:still_life/services/ml/on_device/model_download_types.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';

/// Platform-free surface the settings UI uses to manage downloaded
/// on-device models. The io implementation wraps the store + downloader;
/// on web there is none (the whole on-device section renders as
/// unsupported).
abstract class OnDeviceModelsApi {
  Future<bool> isDownloaded(OnDeviceModel model);

  /// Downloads and verifies [model] (user-initiated only). [onProgress]
  /// reports 0..1 across all files. Throws [ModelDownloadException] on
  /// verification/transport failure, [ModelDownloadCancelled] when
  /// [token] fires.
  Future<void> download(
    OnDeviceModel model, {
    void Function(double fraction)? onProgress,
    ModelDownloadToken? token,
  });

  Future<void> delete(OnDeviceModel model);
}

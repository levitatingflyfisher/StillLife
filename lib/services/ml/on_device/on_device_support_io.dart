import 'dart:io';

import 'package:dio/dio.dart';
import 'package:still_life/services/database/connection/native.dart'
    show resolveAppDocumentsDir;
import 'package:still_life/services/ml/on_device/gateways/llama_vlm_gateway_io.dart';
import 'package:still_life/services/ml/on_device/gateways/mlkit_labeler_gateway_io.dart';
import 'package:still_life/services/ml/on_device/gateways/nano_gateway_io.dart';
import 'package:still_life/services/ml/on_device/labeler_engine.dart';
import 'package:still_life/services/ml/on_device/model_downloader_io.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/model_store_io.dart';
import 'package:still_life/services/ml/on_device/nano_engine.dart';
import 'package:still_life/services/ml/on_device/on_device_models_api.dart';
import 'package:still_life/services/ml/on_device/on_device_support_types.dart';
import 'package:still_life/services/ml/on_device/smolvlm_engine.dart';

export 'package:still_life/services/ml/on_device/on_device_support_types.dart';

/// Android: all three rungs, in quality order. Desktop dev builds and
/// tests get unsupported (the plugins are Android-only).
OnDeviceSupport buildOnDeviceSupport() {
  if (!Platform.isAndroid) {
    return const OnDeviceSupport(supported: false, engines: []);
  }

  final store = IoOnDeviceModelStore(
    resolveBaseDir: () async =>
        '${(await resolveAppDocumentsDir()).path}/on_device_models',
  );

  // A dedicated client: model files are GB-scale, so no receive timeout —
  // stall detection is the connect timeout plus the user's cancel button.
  // validateStatus stays at the default: the transfer engine recognises a
  // 416 by the DioException it raises, so a non-2xx must stay an error.
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

  final nano = AicoreNanoGateway();
  return OnDeviceSupport(
    supported: true,
    engines: [
      NanoEngine(gateway: nano),
      SmolVlmEngine(gateway: LlamaVlmGateway(), store: store),
      LabelerEngine(
        platformSupported: () async => true, // bundled model, Android gate
        labelImage: mlkitLabelImage,
      ),
    ],
    models: _IoOnDeviceModelsApi(
      store: store,
      downloader: IoModelDownloader(store: store, dio: dio),
    ),
    nano: nano,
  );
}

class _IoOnDeviceModelsApi implements OnDeviceModelsApi {
  final IoOnDeviceModelStore store;
  final IoModelDownloader downloader;

  _IoOnDeviceModelsApi({required this.store, required this.downloader});

  @override
  Future<bool> isDownloaded(OnDeviceModel model) => store.isDownloaded(model);

  @override
  Future<void> download(
    OnDeviceModel model, {
    void Function(double fraction)? onProgress,
    ModelDownloadToken? token,
  }) => downloader.download(model, onProgress: onProgress, token: token);

  @override
  Future<void> delete(OnDeviceModel model) => store.delete(model);
}

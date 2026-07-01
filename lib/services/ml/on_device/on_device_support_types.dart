import 'package:still_life/services/ml/on_device/nano_engine.dart';
import 'package:still_life/services/ml/on_device/on_device_engine.dart';
import 'package:still_life/services/ml/on_device/on_device_models_api.dart';

/// Everything the app needs from the on-device AI runtime, built once per
/// platform by `buildOnDeviceSupport()` (io/stub trio). Platform-free
/// types only — safe to import from settings UI that also compiles for
/// web.
class OnDeviceSupport {
  /// False on web and non-Android: no engines, no model management, and
  /// the settings section renders as unsupported.
  final bool supported;

  /// Engines in quality order for [OnDeviceProvider]. Empty when
  /// unsupported.
  final List<OnDeviceEngine> engines;

  /// Model download/delete surface for settings; null when unsupported.
  final OnDeviceModelsApi? models;

  /// Gemini Nano status/setup surface for settings; null when
  /// unsupported.
  final NanoGateway? nano;

  const OnDeviceSupport({
    required this.supported,
    required this.engines,
    this.models,
    this.nano,
  });
}

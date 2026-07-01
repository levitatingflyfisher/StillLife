import 'package:still_life/services/ml/on_device/on_device_support_types.dart';

export 'package:still_life/services/ml/on_device/on_device_support_types.dart';

/// Web: no on-device AI. The tier stays honestly unavailable, exactly as
/// before rungs 1/1.5/2 existed on Android.
OnDeviceSupport buildOnDeviceSupport() =>
    const OnDeviceSupport(supported: false, engines: []);

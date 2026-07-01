import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake for flutter_secure_storage: intercepts the platform
/// channel so any `const FlutterSecureStorage()` in production code reads
/// and writes [values] instead of touching the platform.
class FakeSecureStorageChannel {
  final Map<String, String> values = {};

  void install() {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'read':
              final key = (call.arguments as Map)['key'] as String;
              return values[key];
            case 'write':
              final args = call.arguments as Map;
              values[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              final args = call.arguments as Map;
              values.remove(args['key'] as String);
              return null;
            case 'readAll':
              return Map<String, String>.from(values);
            case 'deleteAll':
              values.clear();
              return null;
            case 'containsKey':
              final key = (call.arguments as Map)['key'] as String;
              return values.containsKey(key);
          }
          return null;
        });
  }

  void uninstall() {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }
}

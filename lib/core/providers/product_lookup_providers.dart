import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final productLookupEnabledProvider =
    AsyncNotifierProvider<ProductLookupSettingNotifier, bool>(
      ProductLookupSettingNotifier.new,
    );

class ProductLookupSettingNotifier extends AsyncNotifier<bool> {
  static const _key = 'product_lookup_enabled';
  final _storage = const FlutterSecureStorage();

  @override
  Future<bool> build() async {
    final val = await _storage.read(key: _key);
    return val == 'true';
  }

  Future<void> setEnabled(bool value) async {
    await _storage.write(key: _key, value: value.toString());
    state = AsyncData(value);
  }
}

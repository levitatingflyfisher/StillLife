import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// Where the theme choice lives. Before this, the choice was held only in
/// memory and every launch forgot it, so there is no older stored value to
/// migrate. Nothing stored, or anything unrecognised, follows the phone.
class ThemePreferenceStore {
  /// App-scoped: on the web every fleet PWA shares one origin's storage.
  static const key = 'stilllife.theme_mode';

  final FlutterSecureStorage _storage;
  const ThemePreferenceStore(this._storage);

  Future<OhThemeModePreference> read() async {
    try {
      return OhThemeModePreference.fromStorage(await _storage.read(key: key));
    } catch (_) {
      // A keystore hiccup must never block launch or pick a theme.
      return OhThemeModePreference.defaultValue;
    }
  }

  Future<void> write(OhThemeModePreference value) async {
    try {
      await _storage.write(key: key, value: value.storageValue);
    } catch (_) {
      // Not saved: the choice still applies for this session.
    }
  }
}

final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => const ThemePreferenceStore(FlutterSecureStorage()),
);

/// Read once in main() before the first frame, so a dark choice does not
/// flash light. Tests and the default use "follow the phone".
final initialThemePreferenceProvider = Provider<OhThemeModePreference>(
  (ref) => OhThemeModePreference.defaultValue,
);

final themePreferenceProvider =
    StateNotifierProvider<ThemePreferenceNotifier, OhThemeModePreference>(
      (ref) => ThemePreferenceNotifier(
        ref.watch(themePreferenceStoreProvider),
        ref.watch(initialThemePreferenceProvider),
      ),
    );

class ThemePreferenceNotifier extends StateNotifier<OhThemeModePreference> {
  final ThemePreferenceStore _store;
  ThemePreferenceNotifier(this._store, super.initial);

  Future<void> set(OhThemeModePreference value) async {
    state = value;
    await _store.write(value);
  }
}

/// What MaterialApp consumes.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themePreferenceProvider).themeMode,
);

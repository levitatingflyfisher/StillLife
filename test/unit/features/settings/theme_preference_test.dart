import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:still_life/features/settings/presentation/controllers/theme_controller.dart';
import 'package:still_life/features/settings/presentation/widgets/theme_toggle_action.dart';

import '../../../mocks/fake_secure_storage_channel.dart';

/// Theme used to live only in memory: every launch forgot the choice. It is
/// now stored, defaults to following the phone, and survives a restart.
/// There is no legacy value to migrate (nothing was ever written).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final channel = FakeSecureStorageChannel();
  setUp(() {
    channel.values.clear();
    channel.install();
  });
  tearDown(channel.uninstall);

  const storage = FlutterSecureStorage();

  test('nothing stored follows the phone', () async {
    expect(
      await const ThemePreferenceStore(storage).read(),
      OhThemeModePreference.system,
    );
  });

  test('a stored choice is read back', () async {
    channel.values[ThemePreferenceStore.key] = 'dark';
    expect(
      await const ThemePreferenceStore(storage).read(),
      OhThemeModePreference.dark,
    );
  });

  test('an unreadable value falls back to following the phone', () async {
    channel.values[ThemePreferenceStore.key] = 'sepia';
    expect(
      await const ThemePreferenceStore(storage).read(),
      OhThemeModePreference.system,
    );
  });

  test('choosing a theme is stored, so the next launch keeps it', () async {
    const store = ThemePreferenceStore(storage);
    final container = ProviderContainer(
      overrides: [
        themePreferenceStoreProvider.overrideWithValue(store),
        initialThemePreferenceProvider.overrideWithValue(
          OhThemeModePreference.system,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(themePreferenceProvider.notifier)
        .set(OhThemeModePreference.light);

    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(await store.read(), OhThemeModePreference.light);
  });

  test('the key is app-scoped: PWAs share one origin', () {
    expect(ThemePreferenceStore.key, startsWith('stilllife'));
  });

  testWidgets('the top-bar toggle reaches Dark in two taps', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(appBar: AppBar(actions: const [ThemeToggleAction()])),
        ),
      ),
    );
    expect(find.text('Auto'), findsOneWidget);

    await tester.tap(find.text('Auto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(channel.values[ThemePreferenceStore.key], 'dark');
  });
}

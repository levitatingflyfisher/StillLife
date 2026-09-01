import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../controllers/theme_controller.dart';

/// The fleet theme control for a tab's top bar: icon plus short label
/// ("Auto", "Light", "Dark"), a menu of the three choices, so any theme is
/// at most two taps from every tab.
class ThemeToggleAction extends ConsumerWidget {
  const ThemeToggleAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OhThemeToggle(
      value: ref.watch(themePreferenceProvider),
      onChanged: (pref) => ref.read(themePreferenceProvider.notifier).set(pref),
    );
  }
}

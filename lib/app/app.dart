import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openhearth_design/openhearth_design.dart';
import '../l10n/arb/app_localizations.dart';

import '../core/providers/bootstrap_provider.dart';
import '../features/settings/presentation/controllers/theme_controller.dart';
import 'router.dart';

class StillLifeApp extends ConsumerWidget {
  const StillLifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seed default categories, property, and rooms on first launch
    ref.watch(bootstrapProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Still Life',
      debugShowCheckedModeBanner: false,
      theme: OhTheme.light(),
      darkTheme: OhTheme.hearthDark(),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

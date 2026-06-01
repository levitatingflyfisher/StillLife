import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app/app.dart';
import 'app/boot.dart';
import 'app/router.dart';
import 'core/providers/billing_providers.dart';
import 'core/providers/notification_providers.dart';
import 'core/providers/repository_providers.dart';
import 'services/deeplinks/deeplink_handler.dart';
import 'services/import/share_intent_handler.dart';
import 'services/import/amazon_import_service.dart';
import 'services/import/bank_statement_parser.dart';
import 'services/import/import_receipt_ocr_service.dart';

ShareIntentHandler? _shareIntentHandler;
AppLifecycleListener? _lifecycleListener;
StreamSubscription<Uri>? _deepLinkSubscription;

/// Runs a launch-time init that must never block startup: it swallows errors
/// and gives up after [timeout], so neither a thrown exception nor a hung
/// platform channel can stop `main()` from reaching `runApp`.
Future<void> _bestEffort(
  Future<void> Function() task, {
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    await task().timeout(timeout);
  } catch (_) {
    // Non-fatal — the app still launches; dependent code re-resolves later.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface async/framework errors instead of swallowing them — otherwise a
  // failure before runApp leaves the app stuck on the splash with no clue why.
  FlutterError.onError = FlutterError.presentError;
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('StillLife uncaught: $error\n$stack');
    return true;
  };

  // Pre-warm path_provider's Pigeon channel and the old-Android sqlite3
  // workaround — but as BEST-EFFORT only. path_provider_android ≥2.2 can throw
  // "Unable to establish connection on channel" if the channel isn't
  // registered yet, and on some devices these calls hang; either used to leave
  // the app frozen on the splash forever because they were awaited unguarded.
  // If they fail now, the LazyDatabase callback simply re-resolves the
  // directory later, once the channel is ready.
  await _bestEffort(() => getApplicationDocumentsDirectory());
  if (Platform.isAndroid) {
    await _bestEffort(() => applyWorkaroundToOpenSqlite3OnOldAndroidVersions());
  }

  // Resolve onboarding without ever throwing (a keystore failure must not brick
  // launch) so the router's initial location is set with no redirect flash.
  const storage = FlutterSecureStorage();
  final initialLocation = await resolveInitialLocation(storage);

  final container = ProviderContainer(
    overrides: [
      routerProvider.overrideWithValue(
        buildAppRouter(initialLocation: initialLocation),
      ),
    ],
  );

  // Initialise local notifications; non-fatal and time-boxed so a hung or
  // throwing notification channel can't block launch.
  final ns = container.read(notificationServiceProvider);
  await _bestEffort(() => ns.initialize());
  ns.requestPermission().catchError(
    (_) => false,
  ); // fire-and-forget permission prompt

  // Seed Consumables category + starter items exactly once; non-fatal.
  final seeder = container.read(consumableSeederProvider);
  await _bestEffort(() => seeder.seedIfNeeded());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const StillLifeApp(),
    ),
  );

  // Wire still-life:// deep links (Stripe Checkout return). Non-fatal if
  // the platform plugin isn't available (e.g. tests).
  final appLinks = AppLinks();
  final deepLinkHandler = DeepLinkHandler(
    billing: container.read(billingServiceProvider),
  );
  try {
    _deepLinkSubscription = appLinks.uriLinkStream.listen((uri) async {
      final handled = await deepLinkHandler.handle(uri);
      if (handled) {
        // Refresh account state so the new bearer is picked up.
        // ignore: unawaited_futures
        container.read(accountProvider.notifier).refresh();
      }
    });
  } catch (_) {
    // Deep links unavailable on this platform — ignore silently.
  }

  // Wire Android share intent after the app is running so the router's
  // navigator key is attached to the widget tree.
  if (Platform.isAndroid) {
    _shareIntentHandler = ShareIntentHandler(
      router: container.read(routerProvider),
      ocrService: ImportReceiptOcrService(
        providerManager: container.read(providerManagerProvider),
      ),
      amazonService: AmazonImportService(),
      bankParser: BankStatementParser(),
    );
    await _shareIntentHandler!.init();

    _lifecycleListener = AppLifecycleListener(
      onDetach: () {
        _shareIntentHandler?.dispose();
        _deepLinkSubscription?.cancel();
        _lifecycleListener?.dispose();
      },
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/providers/billing_providers.dart';
import 'core/providers/notification_providers.dart';
import 'core/providers/repository_providers.dart';
import 'services/deeplinks/deeplink_handler.dart';
import 'services/import/share_intent_handler.dart';
import 'services/import/amazon_import_service.dart';
import 'services/import/bank_statement_parser.dart';
import 'services/import/import_receipt_ocr_service.dart';

const _kOnboardingKey = 'onboarding_v1';

ShareIntentHandler? _shareIntentHandler;
AppLifecycleListener? _lifecycleListener;
StreamSubscription<Uri>? _deepLinkSubscription;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-warm path_provider so its Pigeon channel is established before any
  // Riverpod provider (or LazyDatabase callback) calls it.  Without this,
  // path_provider_android ≥2.2 can throw "Unable to establish connection on
  // channel" on the dashboard because the channel completes registration
  // asynchronously after onAttachedToEngine.
  await getApplicationDocumentsDirectory();

  // Ensure sqlite3 can be loaded on old Android versions (6.0.1 / API 23).
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  // Check onboarding status before creating the router so the initial
  // location is correct without any redirect flash.
  const storage = FlutterSecureStorage();
  final onboarded = await storage.read(key: _kOnboardingKey) == 'complete';

  final container = ProviderContainer(
    overrides: [
      routerProvider.overrideWithValue(
        buildAppRouter(
          initialLocation: onboarded ? '/dashboard' : '/onboarding',
        ),
      ),
    ],
  );

  // Initialise local notifications; errors are non-fatal.
  final ns = container.read(notificationServiceProvider);
  await ns.initialize().catchError((_) {});
  ns.requestPermission().catchError(
    (_) => false,
  ); // fire-and-forget permission prompt

  // Seed Consumables category + starter items exactly once; errors are non-fatal.
  final seeder = container.read(consumableSeederProvider);
  await seeder.seedIfNeeded().catchError((_) {});

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

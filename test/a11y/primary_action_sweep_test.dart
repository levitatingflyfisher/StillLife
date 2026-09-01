import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';
import 'package:still_life/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/core/providers/profile_providers.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:still_life/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:still_life/features/inventory/presentation/screens/item_edit_screen.dart';
import 'package:still_life/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:still_life/features/locations/presentation/screens/rooms_screen.dart';
import 'package:still_life/features/reports/presentation/controllers/policy_controller.dart';
import 'package:still_life/features/reports/presentation/screens/reports_screen.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';
import 'package:still_life/features/profiles/domain/entities/profile.dart'
    as domain;
import 'package:still_life/services/database/database.dart' hide Item;

import '../test_setup.dart';
import 'package:still_life/core/providers/sync_providers.dart';
import 'package:still_life/core/sync/sync_stamp.dart';

/// The release gate for StillLife's primary-action screens
/// (C5-primaryScreens): at 360 dp x 1.3 text the primary action is on
/// screen and tappable, and at 320 dp x 3.0 nothing overflows. Rendered
/// with the real OhTheme, so the 0.7.x type ladder is what is measured.
class _MockItemRepository extends Mock implements ItemRepository {}

class _NoProfile extends ActiveProfileNotifier {
  @override
  Future<domain.Profile?> build() async => null;
}

Item _item(String id, String name) {
  final now = DateTime(2025, 1, 1);
  return Item(
    id: id,
    name: name,
    description: '',
    categoryId: 'c1',
    roomId: 'r1',
    currentValueCents: 129900,
    createdAt: now,
    modifiedAt: now,
  );
}

void main() {
  ensureSqlite3();

  testWidgets('Inventory: the add button is reachable', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              itemRepositoryProvider.overrideWithValue(_MockItemRepository()),
              inventoryItemsProvider.overrideWith(
                (ref) => Stream.value([
                  _item('1', 'Television'),
                  _item('2', 'Grandmother’s writing desk, walnut'),
                ]),
              ),
            ],
            child: MaterialApp(
              theme: OhTheme.light(),
              home: const InventoryScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
      },
      primaryAction: find.byType(FloatingActionButton),
    );
  });

  testWidgets('Add item: Save is reachable', (tester) async {
    final db = AppDatabase.memory();
    final now = DateTime(2026);
    await tester.runAsync(() async {
      await db
          .into(db.properties)
          .insert(
            PropertiesCompanion.insert(
              id: 'prop-1',
              name: 'Home',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.rooms)
          .insert(
            RoomsCompanion.insert(
              id: 'room-1',
              propertyId: 'prop-1',
              name: 'Garage',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat-1',
              name: 'Tools',
              createdAt: now,
              modifiedAt: now,
            ),
          );
    });

    await runPrimaryActionSweep(
      tester,
      pumpScreen: () async {
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const ItemEditScreen()),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              // No keystore in widget tests: writes go unstamped.
              syncStampProvider.overrideWithValue(SyncStamp.none),
              activeProfileProvider.overrideWith(_NoProfile.new),
            ],
            child: MaterialApp.router(
              theme: OhTheme.light(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      },
      primaryAction: find.widgetWithText(TextButton, 'Save'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(db.close);
  });

  // The top bars now carry labelled commands plus the theme toggle; they
  // must still fit on a phone at 1.3x and not overflow at 320 x 3.0.
  testWidgets('Rooms: top bar fits and Settings is reachable', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              roomsProvider.overrideWith((ref) => Stream.value([])),
              propertiesProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              theme: OhTheme.light(),
              home: const RoomsScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
      },
      primaryAction: find.byIcon(Icons.settings_outlined),
    );
  });

  testWidgets('Reports: top bar fits and the theme is reachable', (
    tester,
  ) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dashboardSummaryProvider.overrideWith(
                (ref) async => const DashboardSummary(),
              ),
              policiesProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              theme: OhTheme.light(),
              home: const ReportsScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
      },
      primaryAction: find.byType(OhThemeToggle),
    );
  });

  // The screen the app opens on: title, theme toggle, Search and Settings.
  testWidgets('Dashboard: top bar fits and Search is reachable', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sanctuaryBackupConfigProvider.overrideWithValue(
                const SanctuaryBackupConfig(
                  appId: 'stilllife',
                  aadContext: 'stilllife-backup/v1',
                  appDisplayName: 'Still Life',
                ),
              ),
              databaseProvider.overrideWithValue(db),
              // No keystore in widget tests: writes go unstamped.
              syncStampProvider.overrideWithValue(SyncStamp.none),
              secureKeyStoreProvider.overrideWithValue(
                InMemorySecureKeyStore(),
              ),
              cryptoServiceProvider.overrideWithValue(FakeCryptoService()),
              backupReminderStoreProvider.overrideWithValue(
                InMemoryBackupReminderStore(),
              ),
              dashboardSummaryProvider.overrideWith(
                (ref) async => const DashboardSummary(
                  totalItems: 12,
                  totalCurrentValueCents: 1234500,
                  totalReplacementCostCents: 2345600,
                  totalAcquisitionCostCents: 999900,
                ),
              ),
            ],
            child: MaterialApp(
              theme: OhTheme.light(),
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      },
      primaryAction: find.byIcon(Icons.search),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(db.close);
  });
}

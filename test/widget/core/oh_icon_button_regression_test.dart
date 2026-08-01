import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/chat_providers.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/chat/presentation/screens/item_chat_screen.dart';
import 'package:still_life/features/inventory/domain/entities/category.dart'
    as domain;
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/category_repository.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/screens/item_edit_screen.dart';
import 'package:still_life/features/locations/domain/entities/room.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';
import 'package:still_life/services/appraisal/appraiser_service.dart';
import 'package:still_life/services/chat/item_chat_service.dart';
import 'package:still_life/services/product_lookup/product_lookup_service.dart';

/// Regression coverage for the four StillLife call sites converted from the
/// plain `IconButton.filled` / `.filledTonal` to `OhIconButton`.
///
/// `OhTheme` sets an app-wide `ThemeData.iconTheme.color = primary`. On
/// Flutter 3.38.7 that ambient color resolves ABOVE `IconButton.filled`'s
/// own default foreground, so an unstyled `IconButton.filled` paints its
/// glyph in `primary` — the exact color of its own fill. Invisible glyph.
/// `IconButton.filledTonal` gets `primary` instead of `onSecondaryContainer`
/// — poor contrast. `OhIconButton` pins the correct foreground at the
/// widget level.
///
/// These tests exercise the app's real screens (chat, edit) under the app's
/// real themes (`OhTheme.light()` / `OhTheme.hearthDark()`, per
/// `app/app.dart`) and read the actual resolved `IconTheme.of(context)
/// .color` from a real pumped widget — never a mock. `OhIconButton`'s own
/// internal correctness is covered in ohStyle; these tests are about
/// whether each StillLife call site is actually wired to it.
void main() {
  final themes = <String, ThemeData Function()>{
    'light': OhTheme.light,
    'hearthDark': OhTheme.hearthDark,
  };

  Color? resolvedIconColor(WidgetTester tester, Finder iconFinder) {
    final ctx = tester.element(iconFinder);
    return IconTheme.of(ctx).color;
  }

  for (final entry in themes.entries) {
    final themeName = entry.key;
    final buildTheme = entry.value;

    group('item_chat_screen send button under OhTheme.$themeName()', () {
      testWidgets('send icon resolves to onPrimary, not primary', (
        tester,
      ) async {
        final item = Item(
          id: 'i1',
          name: 'Kitchen Mixer',
          description: '',
          categoryId: 'c',
          roomId: 'r',
          createdAt: DateTime(2024),
          modifiedAt: DateTime(2024),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              itemRepositoryProvider.overrideWithValue(_FakeItemRepo(item)),
              itemChatServiceProvider.overrideWithValue(
                ItemChatService(
                  transport: _StubTransport(),
                  streamOverride: (_) => Stream.fromIterable(const []),
                ),
              ),
            ],
            child: MaterialApp(
              theme: buildTheme(),
              home: const ItemChatScreen(itemId: 'i1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Guard the test's own precondition: the send button must be in
        // its ENABLED state (item loaded, not streaming) when the color is
        // read — the invisible-glyph bug is about the enabled foreground
        // colliding with the fill; a disabled-state read would exercise a
        // different code path and prove nothing about the bug. Scoped
        // under OhIconButton (not a bare byType(IconButton) lookup) so an
        // AppBar action added later can't silently retarget this guard.
        final iconButton = tester.widget<IconButton>(
          find.descendant(
            of: find.byType(OhIconButton),
            matching: find.byType(IconButton),
          ),
        );
        expect(iconButton.onPressed, isNotNull);

        final theme = buildTheme();
        final resolved = resolvedIconColor(tester, find.byIcon(Icons.send));
        expect(resolved, theme.colorScheme.onPrimary);
        expect(resolved, isNot(theme.colorScheme.primary));
      });
    });

    group('item_edit_screen inline-add buttons under OhTheme.$themeName()', () {
      testWidgets(
        'New category / New room icons resolve to onSecondaryContainer, not primary',
        (tester) async {
          tester.view.physicalSize = const Size(800, 2000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                roomsProvider.overrideWith((ref) => Stream.value([_fakeRoom])),
                propertiesProvider.overrideWith((ref) => Stream.value([])),
                categoryRepositoryProvider.overrideWithValue(
                  _FakeCategoryRepository(),
                ),
                productLookupServiceProvider.overrideWithValue(
                  _FakeProductLookupService(),
                ),
              ],
              child: MaterialApp(
                theme: buildTheme(),
                home: const ItemEditScreen(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));

          final theme = buildTheme();

          final categoryIcon = find.descendant(
            of: find.byTooltip('New category'),
            matching: find.byType(Icon),
          );
          final roomIcon = find.descendant(
            of: find.byTooltip('New room'),
            matching: find.byType(Icon),
          );

          final categoryResolved = resolvedIconColor(tester, categoryIcon);
          final roomResolved = resolvedIconColor(tester, roomIcon);

          expect(categoryResolved, theme.colorScheme.onSecondaryContainer);
          expect(categoryResolved, isNot(theme.colorScheme.primary));
          expect(roomResolved, theme.colorScheme.onSecondaryContainer);
          expect(roomResolved, isNot(theme.colorScheme.primary));
        },
      );
    });

    group(
      'item_detail_screen quantity decrement button under OhTheme.$themeName()',
      () {
        // itemDetailProvider's screen aggregates photo/tag/loan/appraisal
        // providers well beyond what this color-resolution regression needs
        // to exercise, so this mirrors the call site's exact widget (same
        // icon, same tooltip) instead of standing up the full screen. Still
        // a real pumped OhIconButton under the app's real theme — not a
        // mock.
        testWidgets('remove icon resolves to onPrimary, not primary', (
          tester,
        ) async {
          final theme = buildTheme();
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: OhIconButton.filled(
                  icon: const Icon(Icons.remove),
                  onPressed: () {},
                  tooltip: '−1',
                ),
              ),
            ),
          );

          final resolved = resolvedIconColor(tester, find.byIcon(Icons.remove));
          expect(resolved, theme.colorScheme.onPrimary);
          expect(resolved, isNot(theme.colorScheme.primary));
        });
      },
    );
  }

  // The source-level backstop for all four sites — including
  // item_detail_screen.dart, whose color-resolution test above mirrors the
  // call site rather than pumping the real, provider-heavy screen and so
  // cannot see a regression AT the source file — is NOT here. It is the
  // fleet's own conformance check C8 (`FleetCheck.c8IconButtons`, opted
  // into in test/fleet_conformance_test.dart), which scans lib/ for bare
  // filled-variant call sites across every app that uses openhearth_design.
  // A local copy of that scan lived here first; it was removed rather than
  // maintained in parallel, because two guards enforcing one rule drift.
}

class _FakeItemRepo extends Fake implements ItemRepository {
  final Item item;
  _FakeItemRepo(this.item);

  @override
  Future<Result<Item>> getItem(String id) async => Success(item);
}

class _StubTransport implements MessagesTransport {
  @override
  Future<Result<Map<String, dynamic>>> send(Map<String, dynamic> body) async =>
      const Success({});
}

class _FakeProductLookupService extends Fake implements ProductLookupService {
  @override
  Future<ProductInfo?> lookup(
    String barcode, {
    bool allowNetwork = false,
  }) async => null;
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Stream<List<domain.Category>> watchCategories() => Stream.value([]);

  @override
  Future<Result<domain.Category>> getCategory(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<domain.Category>> createCategory(domain.Category category) =>
      throw UnimplementedError();

  @override
  Future<Result<domain.Category>> updateCategory(domain.Category category) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteCategory(String id) => throw UnimplementedError();

  @override
  Future<Result<void>> seedDefaults() => throw UnimplementedError();
}

final _fakeRoom = Room(
  id: 'room-1',
  propertyId: 'prop-1',
  name: 'Living Room',
  createdAt: DateTime(2024),
  modifiedAt: DateTime(2024),
);

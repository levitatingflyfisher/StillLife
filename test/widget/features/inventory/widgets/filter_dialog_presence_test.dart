import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/presentation/controllers/category_controller.dart';
import 'package:still_life/features/inventory/presentation/controllers/tag_controller.dart';
import 'package:still_life/features/inventory/presentation/widgets/filter_dialog.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';

Widget _wrapInSheet(Widget child) {
  return ProviderScope(
    overrides: [
      roomsProvider.overrideWith((ref) => Stream.value([])),
      categoriesProvider.overrideWith((ref) => Stream.value([])),
      tagsProvider.overrideWith((ref) => Stream.value([])),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('presence chips render', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrapInSheet(const FilterDialog(currentFilter: FilterResult())),
    );
    await tester.pump();

    expect(find.text('Has Photo'), findsOneWidget);
    expect(find.text('Has Receipt'), findsOneWidget);
    expect(find.text('Has Barcode'), findsOneWidget);
  });

  testWidgets('date added section renders', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrapInSheet(const FilterDialog(currentFilter: FilterResult())),
    );
    await tester.pump();

    expect(find.text('Date Added'), findsOneWidget);
  });

  testWidgets('tapping Has Photo chip sets hasPhoto in returned FilterResult', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Render FilterDialog directly (not in a modal) so all content is in the
    // flat widget tree and visible within the viewport height.  We intercept
    // the Navigator.pop result by wrapping in a Navigator whose onPopPage
    // captures the value.
    FilterResult? result;
    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomsProvider.overrideWith((ref) => Stream.value([])),
          categoriesProvider.overrideWith((ref) => Stream.value([])),
          tagsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          navigatorKey: navKey,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(ctx).push<FilterResult>(
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: FilterDialog(currentFilter: FilterResult()),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Has Photo'));
    await tester.pump();
    await tester.tap(find.text('Apply Filters'));
    await tester.pump();

    expect(result?.hasPhoto, isTrue);
  });
}

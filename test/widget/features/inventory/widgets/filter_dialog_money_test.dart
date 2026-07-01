import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/presentation/controllers/category_controller.dart';
import 'package:still_life/features/inventory/presentation/controllers/tag_controller.dart';
import 'package:still_life/features/inventory/presentation/widgets/filter_dialog.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';

/// Money-input behavior on the filter form: comma-decimal values must parse
/// and garbage must show a field error instead of silently applying no
/// price filter.
void main() {
  testWidgets('comma-decimal Min value parses into the FilterResult',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Min'),
      '12,50',
    );
    await tester.tap(find.text('Apply Filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(result, isNotNull);
    expect(result!.minValueCents, 1250,
        reason: 'comma-decimal money must parse, not silently drop');
  });

  testWidgets('unparseable Min value shows a field error and blocks Apply',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    FilterResult? result;
    var popped = false;
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
                  popped = true;
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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Min'),
      'abc',
    );
    await tester.tap(find.text('Apply Filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Enter a valid amount'), findsOneWidget,
        reason: 'the field must surface a validation error');
    expect(popped, isFalse,
        reason: 'the dialog must not apply while a money field is garbage');
    expect(result, isNull);
  });

  testWidgets('ambiguous "1,234" Min value shows the actionable message',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var popped = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roomsProvider.overrideWith((ref) => Stream.value([])),
          categoriesProvider.overrideWith((ref) => Stream.value([])),
          tagsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  await Navigator.of(ctx).push<FilterResult>(
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: FilterDialog(currentFilter: FilterResult()),
                      ),
                    ),
                  );
                  popped = true;
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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Min'),
      '1,234',
    );
    await tester.tap(find.text('Apply Filters'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ambiguous amount — use 1234 or 1,234.00'), findsOneWidget,
        reason: 'the filter must refuse the ambiguous reading too');
    expect(popped, isFalse,
        reason: 'the dialog must not apply an ambiguous money filter');
  });
}

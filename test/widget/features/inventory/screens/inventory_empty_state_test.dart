import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:still_life/features/inventory/presentation/screens/inventory_screen.dart';

class _MockItemRepository extends Mock implements ItemRepository {}

double _luminance(Color c) => c.computeLuminance();
double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Color _over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

/// The first screen a new household sees. It must name the action in words
/// (writing-is-designing-03: "Tap +" names a glyph a screen reader cannot
/// read) and its sentence must be readable (mind-in-mind-03: alpha 120 was
/// 3.0:1).
void main() {
  for (final (name, theme) in [
    ('light', OhTheme.light()),
    ('dark', OhTheme.hearthDark()),
  ]) {
    testWidgets('empty Inventory names "Add item" and reads at 4.5:1 ($name)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            itemRepositoryProvider.overrideWithValue(_MockItemRepository()),
            inventoryItemsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(theme: theme, home: const InventoryScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Tap +'), findsNothing);
      final line = find.textContaining('Add item');
      expect(line, findsWidgets);

      // The button carries the same words as the sentence.
      expect(
        find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.text('Add item'),
        ),
        findsOneWidget,
      );

      final sentence = tester.widget<Text>(
        find.textContaining('to start your catalogue'),
      );
      final bg = theme.scaffoldBackgroundColor;
      final fg = _over(sentence.style!.color!, bg);
      expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5));
    });
  }
}

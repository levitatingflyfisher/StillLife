import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:still_life/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:still_life/features/recently_deleted/data/recently_deleted_repository.dart';
import 'package:still_life/features/recently_deleted/presentation/undo_providers.dart';

class MockItemRepository extends Mock implements ItemRepository {}

class MockRecentlyDeleted extends Mock implements RecentlyDeletedRepository {}

Item _makeItem(String id, String name) {
  final now = DateTime(2025, 1, 1);
  return Item(
    id: id,
    name: name,
    description: '',
    categoryId: 'c1',
    roomId: 'r1',
    createdAt: now,
    modifiedAt: now,
  );
}

late MockRecentlyDeleted trash;
late ProviderContainer container;

Widget buildSubject(ItemRepository repo, List<Item> items) {
  container = ProviderContainer(
    overrides: [
      recentlyDeletedRepositoryProvider.overrideWithValue(trash),
      itemRepositoryProvider.overrideWithValue(repo),
      inventoryItemsProvider.overrideWith((ref) => Stream.value(items)),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: InventoryScreen()),
  );
}

const _deletion = ItemDeletion(['1'], {'1': <String>[]});

void main() {
  late MockItemRepository mockRepo;

  setUpAll(() => registerFallbackValue(_deletion));

  setUp(() {
    mockRepo = MockItemRepository();
    trash = MockRecentlyDeleted();
    when(() => trash.snapshot(any())).thenAnswer((_) async => _deletion);
    when(() => trash.restoreItems(any())).thenAnswer((_) async {});
  });

  group('InventoryScreen bulk operations', () {
    testWidgets('long-press enters selection mode', (tester) async {
      final items = [_makeItem('1', 'TV'), _makeItem('2', 'Lamp')];
      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping item in selection mode selects it', (tester) async {
      final items = [_makeItem('1', 'TV'), _makeItem('2', 'Lamp')];
      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      // Enter selection mode via long-press
      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      // Tap second item to select it
      await tester.tap(find.text('Lamp'));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('close button exits selection mode', (tester) async {
      final items = [_makeItem('1', 'TV')];
      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets('Delete acts at once: no question, and a lasting Undo', (
      tester,
    ) async {
      final items = [_makeItem('1', 'TV')];
      when(
        () => mockRepo.deleteItems(any()),
      ).thenAnswer((_) async => const Success(null));

      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // A deliberate delete does not ask (operator ruling), and never
      // claims it "cannot be undone": the delete is soft.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('cannot be undone'), findsNothing);
      verify(() => mockRepo.deleteItems(['1'])).called(1);

      final undo = container.read(shellUndoControllerProvider);
      expect(undo.pending?.message, 'Deleted 1 item');
      // No timer: an hour later the offer is still there.
      await tester.pump(const Duration(hours: 1));
      expect(undo.pending, isNotNull);

      await undo.undo();
      verify(() => trash.restoreItems(_deletion)).called(1);
    });

    testWidgets('delete failure says so plainly and stays in selection mode', (
      tester,
    ) async {
      final items = [_makeItem('1', 'TV')];
      when(
        () => mockRepo.deleteItems(any()),
      ).thenAnswer((_) async => const Err(DatabaseFailure('disk full')));

      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining("Couldn’t delete the items"), findsOneWidget);
      expect(container.read(shellUndoControllerProvider).pending, isNull);
      // Selection mode is preserved on failure so the user can retry.
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('FAB hidden in selection mode', (tester) async {
      final items = [_makeItem('1', 'TV')];
      await tester.pumpWidget(buildSubject(mockRepo, items));
      await tester.pumpAndSettle();

      // FAB visible before selection
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.longPress(find.text('TV'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('Inventory top bar', () {
    testWidgets('every command is named, the title is whole, and words '
        'fold right to left at 360 dp x 1.3', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildSubject(mockRepo, [_makeItem('1', 'TV')]));
      await tester.pumpAndSettle();

      // openhearth_design 0.9 folds bar words by space: a word stays while
      // it fits beside the whole title and folds (rightmost first) into its
      // tooltip otherwise.
      final title = tester.renderObject<RenderParagraph>(find.descendant(
          of: find.byType(AppBar), matching: find.text('Inventory')));
      expect(title.didExceedMaxLines, isFalse, reason: 'title cut off');
      final shown = <bool>[];
      for (final label in ['Search', 'Filter', 'More']) {
        final f = find.text(label);
        final visible = f.evaluate().isNotEmpty;
        if (visible) {
          expect(tester.getRect(f).right, lessThanOrEqualTo(360),
              reason: '$label is cut off');
        } else {
          expect(find.byTooltip(label), findsOneWidget, reason: label);
        }
        shown.add(visible);
      }
      expect(shown.first, isTrue, reason: 'Search keeps its word');
      for (var i = 1; i < shown.length; i++) {
        if (shown[i]) expect(shown[i - 1], isTrue, reason: 'fold order');
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      expect(find.text('Sort by value'), findsOneWidget);
      expect(find.text('Theme: dark'), findsOneWidget);
    });
  });
}

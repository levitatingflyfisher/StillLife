import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/scanning/presentation/screens/barcode_scanner_screen.dart';

void main() {
  const fakeBarcode = Barcode(rawValue: '012345678');

  final fakeItem = Item(
    id: 'item-1',
    name: 'Test TV',
    description: '',
    categoryId: 'cat-1',
    roomId: 'room-1',
    isInsured: false,
    createdAt: DateTime(2024),
    modifiedAt: DateTime(2024),
  );

  Widget buildSheet({
    Item? existingItem,
    VoidCallback? onScanAgain,
    VoidCallback? onAddToInventory,
    VoidCallback? onViewItem,
    VoidCallback? onEditItem,
    VoidCallback? onMoveItem,
    VoidCallback? onLogMaintenance,
  }) => MaterialApp(
    home: Scaffold(
      body: BarcodeResultSheet(
        barcode: fakeBarcode,
        existingItem: existingItem,
        onScanAgain: onScanAgain ?? () {},
        onAddToInventory: onAddToInventory,
        onViewItem: onViewItem,
        onEditItem: onEditItem,
        onMoveItem: onMoveItem,
        onLogMaintenance: onLogMaintenance,
      ),
    ),
  );

  group('BarcodeResultSheet', () {
    testWidgets('shows "Add to Inventory" when item not in inventory', (
      tester,
    ) async {
      await tester.pumpWidget(buildSheet());
      expect(find.text('Add to Inventory'), findsOneWidget);
      expect(find.text('View Item'), findsNothing);
    });

    testWidgets('shows "View Item" and item name when item exists', (
      tester,
    ) async {
      await tester.pumpWidget(buildSheet(existingItem: fakeItem));
      expect(find.text('View Item'), findsOneWidget);
      expect(find.text('Add to Inventory'), findsNothing);
      expect(find.text('Test TV'), findsOneWidget);
    });

    testWidgets('always shows "Scan Again" when no item', (tester) async {
      await tester.pumpWidget(buildSheet());
      expect(find.text('Scan Again'), findsOneWidget);
    });

    testWidgets('always shows "Scan Again" when item exists', (tester) async {
      await tester.pumpWidget(buildSheet(existingItem: fakeItem));
      expect(find.text('Scan Again'), findsOneWidget);
    });

    testWidgets('shows "In Inventory" label when item exists', (tester) async {
      await tester.pumpWidget(buildSheet(existingItem: fakeItem));
      expect(find.text('In Inventory'), findsOneWidget);
    });

    testWidgets('calls onViewItem when "View Item" tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildSheet(existingItem: fakeItem, onViewItem: () => tapped = true),
      );
      await tester.tap(find.text('View Item'));
      expect(tapped, isTrue);
    });

    testWidgets('calls onScanAgain when "Scan Again" tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSheet(onScanAgain: () => tapped = true));
      await tester.tap(find.text('Scan Again'));
      expect(tapped, isTrue);
    });

    testWidgets('calls onAddToInventory when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildSheet(onAddToInventory: () => tapped = true),
      );
      await tester.tap(find.text('Add to Inventory'));
      expect(tapped, isTrue);
    });

    testWidgets('shows barcode value in card', (tester) async {
      await tester.pumpWidget(buildSheet());
      expect(find.text('012345678'), findsOneWidget);
    });

    testWidgets('shows action row icons for existing item', (tester) async {
      await tester.pumpWidget(buildSheet(existingItem: fakeItem));
      await tester.pump();
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.drive_file_move_outlined), findsOneWidget);
      expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    });

    testWidgets('does not show action row icons for new item', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.drive_file_move_outlined), findsNothing);
      expect(find.byIcon(Icons.build_outlined), findsNothing);
    });

    testWidgets('calls onEditItem when edit icon tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildSheet(existingItem: fakeItem, onEditItem: () => called = true),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(called, isTrue);
    });

    testWidgets('calls onMoveItem when move icon tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildSheet(existingItem: fakeItem, onMoveItem: () => called = true),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.drive_file_move_outlined));
      expect(called, isTrue);
    });

    testWidgets('calls onLogMaintenance when maintenance icon tapped', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        buildSheet(
          existingItem: fakeItem,
          onLogMaintenance: () => called = true,
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.build_outlined));
      expect(called, isTrue);
    });
  });
}

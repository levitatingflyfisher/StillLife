import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/presentation/widgets/item_list_tile.dart';

void main() {
  group('ItemListTile', () {
    final testItem = Item(
      id: '1',
      name: 'Samsung TV',
      description: '55 inch OLED',
      categoryId: 'cat1',
      roomId: 'room1',
      currentValue: 899.99,
      categoryName: 'Electronics',
      roomName: 'Living Room',
      createdAt: DateTime(2024, 1, 1),
      modifiedAt: DateTime(2024, 1, 1),
    );

    testWidgets('displays item name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ItemListTile(item: testItem)),
        ),
      );

      expect(find.text('Samsung TV'), findsOneWidget);
    });

    testWidgets('displays category and room in subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ItemListTile(item: testItem)),
        ),
      );

      expect(find.text('Electronics - Living Room'), findsOneWidget);
    });

    testWidgets('displays formatted current value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ItemListTile(item: testItem)),
        ),
      );

      // Currency formatting should show the value
      expect(find.textContaining('899'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemListTile(item: testItem, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });

    testWidgets('handles item without value gracefully', (tester) async {
      final itemNoValue = Item(
        id: '2',
        name: 'Mystery Item',
        description: '',
        categoryId: 'cat1',
        roomId: 'room1',
        currentValue: null,
        createdAt: DateTime(2024, 1, 1),
        modifiedAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ItemListTile(item: itemNoValue)),
        ),
      );

      expect(find.text('Mystery Item'), findsOneWidget);
    });
  });
}

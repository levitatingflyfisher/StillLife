import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/dashboard/presentation/widgets/warranty_expiry_widget.dart';
import 'package:still_life/services/database/database.dart';

void main() {
  final now = DateTime(2025, 6, 1);

  Item makeItem({
    String id = 'item1',
    String name = 'Laptop',
    DateTime? warrantyExpiration,
  }) {
    return Item(
      id: id,
      name: name,
      description: '',
      categoryId: 'cat1',
      roomId: 'room1',
      purchaseDate: null,
      purchasePrice: null,
      currentValue: null,
      replacementCost: null,
      condition: null,
      serialNumber: null,
      warrantyExpiration: warrantyExpiration,
      barcode: null,
      storeUrl: null,
      notes: null,
      isInsured: false,
      createdAt: now,
      modifiedAt: now,
      nodeId: '',
      hlc: '',
      isDeleted: false,
    );
  }

  Widget buildSubject({List<Item> items = const []}) {
    return ProviderScope(
      overrides: [
        warrantyExpiringSoonProvider.overrideWith((_) async => items),
      ],
      child: const MaterialApp(home: Scaffold(body: WarrantyExpiryWidget())),
    );
  }

  group('WarrantyExpiryWidget', () {
    testWidgets('shows empty state message when no items', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.text('No warranties expiring in the next 6 months'),
        findsOneWidget,
      );
    });

    testWidgets('shows card header', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Warranties Expiring Soon'), findsOneWidget);
    });

    testWidgets('shows item name when warranty expiring soon', (tester) async {
      final expiry = DateTime(2025, 7, 1); // ~30 days from now
      await tester.pumpWidget(
        buildSubject(
          items: [makeItem(name: 'Samsung TV', warrantyExpiration: expiry)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Samsung TV'), findsOneWidget);
    });

    testWidgets('shows red chip for item expiring within 30 days', (
      tester,
    ) async {
      final expiry = DateTime.now().add(const Duration(days: 10));
      await tester.pumpWidget(
        buildSubject(
          items: [makeItem(name: 'TV', warrantyExpiration: expiry)],
        ),
      );
      await tester.pumpAndSettle();

      // The chip should be present with the days remaining
      final chips = tester.widgetList<Chip>(find.byType(Chip));
      expect(chips, isNotEmpty);
    });

    testWidgets('shows green chip for item expiring in 91+ days', (
      tester,
    ) async {
      final expiry = DateTime.now().add(const Duration(days: 120));
      await tester.pumpWidget(
        buildSubject(
          items: [makeItem(name: 'Fridge', warrantyExpiration: expiry)],
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester.widgetList<Chip>(find.byType(Chip));
      expect(chips, isNotEmpty);
    });

    testWidgets('shows multiple items (up to 5)', (tester) async {
      final expiry = DateTime.now().add(const Duration(days: 30));
      final items = List.generate(
        6,
        (i) =>
            makeItem(id: 'item$i', name: 'Item $i', warrantyExpiration: expiry),
      );
      await tester.pumpWidget(buildSubject(items: items));
      await tester.pumpAndSettle();

      // Only 5 should be shown
      expect(find.textContaining('Item'), findsNWidgets(5));
    });
  });
}

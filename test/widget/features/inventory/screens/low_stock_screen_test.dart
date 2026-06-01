import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/presentation/controllers/quantity_controller.dart';
import 'package:still_life/features/inventory/presentation/screens/low_stock_screen.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/services/export/csv_export_service.dart';

class _FakeRepo extends Fake implements ItemRepository {
  @override
  Stream<List<Item>> watchLowStockItems() => Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeCsvService extends Fake implements CsvExportService {
  @override
  Future<String> exportShoppingListToCsv() async => '"Name"\n"Coffee"\n';
}

Item _lowItem(String id, String name) => Item(
  id: id,
  name: name,
  description: '',
  categoryId: 'c1',
  roomId: 'r1',
  isInsured: false,
  createdAt: DateTime(2026),
  modifiedAt: DateTime(2026),
  quantity: 1.0,
  lowStockThreshold: 5.0,
);

Widget _wrap(List<Item> items) => ProviderScope(
  overrides: [
    lowStockItemsProvider.overrideWith((ref) => Stream.value(items)),
    csvExportServiceProvider.overrideWithValue(_FakeCsvService()),
    itemRepositoryProvider.overrideWithValue(_FakeRepo()),
  ],
  child: const MaterialApp(home: LowStockScreen()),
);

void main() {
  testWidgets('shows empty state when no low-stock items', (tester) async {
    await tester.pumpWidget(_wrap([]));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('No items are running low'), findsOneWidget);
  });

  testWidgets('shows item names for low-stock items', (tester) async {
    await tester.pumpWidget(
      _wrap([_lowItem('i1', 'Coffee'), _lowItem('i2', 'Dish Soap')]),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Dish Soap'), findsOneWidget);
  });

  testWidgets('shows Export Shopping List button when items exist', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap([_lowItem('i1', 'Coffee')]));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Export Shopping List'), findsOneWidget);
  });

  testWidgets('hides Export Shopping List button when list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap([]));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Export Shopping List'), findsNothing);
  });
}

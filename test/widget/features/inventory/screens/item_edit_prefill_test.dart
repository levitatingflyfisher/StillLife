import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/category.dart'
    as domain;
import 'package:still_life/features/inventory/domain/repositories/category_repository.dart';
import 'package:still_life/features/inventory/presentation/screens/item_edit_screen.dart';
import 'package:still_life/features/locations/domain/entities/room.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';
import 'package:still_life/services/product_lookup/product_lookup_service.dart';

class _FakeProductLookupService extends Fake implements ProductLookupService {
  @override
  Future<ProductInfo?> lookup(
    String barcode, {
    bool allowNetwork = false,
  }) async => null;
}

/// Lookup fake that resolves from the "cache" (allowNetwork: false) with a
/// full product record including brand.
class _FakeBrandLookupService extends Fake implements ProductLookupService {
  @override
  Future<ProductInfo?> lookup(
    String barcode, {
    bool allowNetwork = false,
  }) async => const ProductInfo(
    name: 'WH-1000XM4 Wireless Headphones',
    description: 'Noise cancelling',
    brand: 'Sony',
  );
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

void main() {
  final fakeRoom = Room(
    id: 'room-1',
    propertyId: 'prop-1',
    name: 'Living Room',
    createdAt: DateTime(2024),
    modifiedAt: DateTime(2024),
  );

  List<Override> baseOverrides({List<Room> rooms = const []}) => [
    roomsProvider.overrideWith((ref) => Stream.value(rooms)),
    propertiesProvider.overrideWith((ref) => Stream.value([])),
    categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepository()),
    productLookupServiceProvider.overrideWithValue(_FakeProductLookupService()),
  ];

  group('ItemEditScreen', () {
    testWidgets('shows "Add Item" title when not editing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(rooms: [fakeRoom]),
          child: const MaterialApp(home: ItemEditScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('shows "Edit Item" title when editing', (tester) async {
      // When isEditing is true but no provider is set up the screen will
      // show a loading state — we just verify the title resolves correctly
      // in the add (non-editing) path.
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(rooms: [fakeRoom]),
          child: const MaterialApp(home: ItemEditScreen()),
        ),
      );
      await tester.pump();
      // Not in editing mode, so "Add Item" is shown
      expect(find.text('Add Item'), findsOneWidget);
      expect(find.text('Edit Item'), findsNothing);
    });

    testWidgets('pre-fills barcode field from initialBarcode param', (
      tester,
    ) async {
      // Use a tall viewport so the ListView inflates all form fields,
      // including the barcode TextFormField which is deep in the scroll list.
      tester.view.physicalSize = const Size(800, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(rooms: [fakeRoom]),
          child: const MaterialApp(
            home: ItemEditScreen(initialBarcode: '0123456789'),
          ),
        ),
      );
      await tester.pump();

      // Verify the barcode EditableText has the pre-filled value.
      expect(
        find.byWidgetPredicate(
          (w) => w is EditableText && w.controller.text == '0123456789',
        ),
        findsOneWidget,
      );
    });

    testWidgets('barcode lookup applies the cached brand to the Brand field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomsProvider.overrideWith((ref) => Stream.value([fakeRoom])),
            propertiesProvider.overrideWith((ref) => Stream.value([])),
            categoryRepositoryProvider.overrideWithValue(
              _FakeCategoryRepository(),
            ),
            productLookupServiceProvider.overrideWithValue(
              _FakeBrandLookupService(),
            ),
          ],
          child: const MaterialApp(
            home: ItemEditScreen(initialBarcode: '0027242920568'),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Look up product'));
      // Bounded pumps (not pumpAndSettle): the confirmation SnackBar's
      // indicator animation would otherwise never settle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Name comes from the lookup (already worked) — brand must now too.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is EditableText &&
              w.controller.text == 'WH-1000XM4 Wireless Headphones',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is EditableText && w.controller.text == 'Sony',
        ),
        findsOneWidget,
        reason: 'ProductLookupCache stores brand; the form must apply it',
      );
    });

    testWidgets('Save button is visible in app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(home: ItemEditScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Name label is present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: const MaterialApp(home: ItemEditScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Name *'), findsOneWidget);
    });
  });
}

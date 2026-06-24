import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/category.dart'
    as domain;
import 'package:still_life/features/inventory/domain/entities/item_suggestion.dart';
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

List<Override> _baseOverrides() => [
  roomsProvider.overrideWith((ref) => Stream.value([_fakeRoom])),
  propertiesProvider.overrideWith((ref) => Stream.value([])),
  categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepository()),
  productLookupServiceProvider.overrideWithValue(_FakeProductLookupService()),
];

void main() {
  group('ItemEditScreen — suggestion pre-fill + AI banner', () {
    testWidgets('pre-fills name from ItemSuggestion', (tester) async {
      tester.view.physicalSize = const Size(800, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(),
          child: const MaterialApp(
            home: ItemEditScreen(
              initialSuggestion: ItemSuggestion(name: 'Bosch Drill'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byWidgetPredicate(
          (w) => w is EditableText && w.controller.text == 'Bosch Drill',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows AI banner when showAiBanner is true', (tester) async {
      tester.view.physicalSize = const Size(800, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(),
          child: const MaterialApp(home: ItemEditScreen(showAiBanner: true)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Set up AI analysis'), findsOneWidget);
    });
  });
}

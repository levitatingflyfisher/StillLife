import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/controllers/category_controller.dart';
import 'package:still_life/features/locations/domain/entities/room.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';
import 'package:still_life/features/search/data/services/saved_search_service.dart';
import 'package:still_life/features/search/presentation/controllers/search_controller.dart';
import 'package:still_life/features/search/presentation/screens/search_screen.dart';

class _FakeItemRepo extends Fake implements ItemRepository {
  final List<Item> items;
  _FakeItemRepo(this.items);
  @override
  Stream<List<Item>> watchItems(ItemQuery query) => Stream.value(items);
  @override
  Stream<List<Item>> searchItems(String query) => Stream.value(
    items
        .where((i) => i.name.toLowerCase().contains(query.toLowerCase()))
        .toList(),
  );
}

class _FakeSavedSearchService extends Fake implements SavedSearchService {
  @override
  Future<List<SavedSearch>> load() async => [];
  @override
  Future<void> save(SavedSearch search) async {}
}

Item _item(String id, String name, String roomId) => Item(
  id: id,
  name: name,
  description: '',
  categoryId: 'c1',
  roomId: roomId,
  createdAt: DateTime(2025),
  modifiedAt: DateTime(2025),
);

Room _room(String id, String name) => Room(
  id: id,
  propertyId: 'p',
  name: name,
  sortOrder: 0,
  createdAt: DateTime(2025),
  modifiedAt: DateTime(2025),
);

Widget _buildApp(
  Widget screen, {
  ItemRepository? repo,
  List<Room> rooms = const [],
  List<SavedSearch> savedSearches = const [],
}) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (ctx, s) => screen)],
  );
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(repo ?? _FakeItemRepo([])),
      roomsProvider.overrideWith((ref) => Stream.value(rooms)),
      categoriesProvider.overrideWith((ref) => Stream.value([])),
      allContainersProvider.overrideWith((ref) => Stream.value([])),
      savedSearchServiceProvider.overrideWithValue(_FakeSavedSearchService()),
      savedSearchesProvider.overrideWith((ref) async => savedSearches),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows saved searches chip row when query empty', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        const SearchScreen(),
        savedSearches: [const SavedSearch(label: 'cameras', query: 'cameras')],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('cameras'), findsOneWidget);
  });

  testWidgets('where-is card appears for "where is my" prefix', (tester) async {
    final room = _room('r1', 'Living Room');
    final item = _item('i1', 'Sony Camera', 'r1');
    await tester.pumpWidget(
      _buildApp(
        const SearchScreen(),
        repo: _FakeItemRepo([item]),
        rooms: [room],
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'where is my sony camera');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Living Room'), findsWidgets);
  });

  testWidgets('bookmark button appears when results present', (tester) async {
    final item = _item('i1', 'Camera', 'r1');
    await tester.pumpWidget(
      _buildApp(const SearchScreen(), repo: _FakeItemRepo([item])),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'camera');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
  });
}

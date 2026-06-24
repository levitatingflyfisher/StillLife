import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';

/// Current query state for the inventory list.
final inventoryQueryProvider = StateProvider<ItemQuery>((ref) {
  return const ItemQuery(sortBy: ItemSortField.name, ascending: true);
});

/// Reactive list of items based on the current query.
/// When searchText is set, uses FTS5 full-text search; otherwise uses
/// the filtered watch stream.
final inventoryItemsProvider = StreamProvider<List<Item>>((ref) {
  final query = ref.watch(inventoryQueryProvider);
  final repo = ref.watch(itemRepositoryProvider);
  final text = query.searchText;
  if (text != null && text.isNotEmpty) {
    return repo.searchItems(text);
  }
  return repo.watchItems(query);
});

/// Search results.
final itemSearchProvider = StreamProvider.family<List<Item>, String>((
  ref,
  query,
) {
  if (query.isEmpty) return const Stream.empty();
  final repo = ref.watch(itemRepositoryProvider);
  return repo.searchItems(query);
});

/// Controller for item CRUD operations.
final itemControllerProvider = AsyncNotifierProvider<ItemController, void>(
  ItemController.new,
);

class ItemController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  ItemRepository get _repo => ref.read(itemRepositoryProvider);

  Future<bool> createItem(Item item) async {
    state = const AsyncLoading();
    final result = await _repo.createItem(item);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> updateItem(Item item) async {
    state = const AsyncLoading();
    final result = await _repo.updateItem(item);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> deleteItem(String id) async {
    state = const AsyncLoading();
    final result = await _repo.deleteItem(id);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> moveItems(List<String> itemIds, String newRoomId) async {
    state = const AsyncLoading();
    final result = await _repo.moveItems(itemIds, newRoomId);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

/// Single item provider (by ID). Streams updates so detail/edit screens
/// refresh automatically after CRUD operations.
final itemDetailProvider = StreamProvider.family<Item?, String>((ref, itemId) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchItem(itemId);
});

/// Reactive search results — re-subscribes when [query] changes so
/// callers (e.g. SearchScreen) don't need to wire StreamBuilders manually.
final searchItemsProvider = StreamProvider.family<List<Item>, String>((
  ref,
  query,
) {
  if (query.isEmpty) return const Stream.empty();
  final repo = ref.watch(itemRepositoryProvider);
  return repo.searchItems(query);
});

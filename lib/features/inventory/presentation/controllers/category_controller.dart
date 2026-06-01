import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

/// Watch all categories.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

/// Category CRUD controller.
final categoryControllerProvider =
    AsyncNotifierProvider<CategoryController, void>(CategoryController.new);

class CategoryController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  Future<bool> createCategory(Category category) async {
    state = const AsyncLoading();
    final result = await _repo.createCategory(category);
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

  Future<bool> updateCategory(Category category) async {
    state = const AsyncLoading();
    final result = await _repo.updateCategory(category);
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

  Future<bool> deleteCategory(String id) async {
    state = const AsyncLoading();
    final result = await _repo.deleteCategory(id);
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

  Future<bool> seedDefaults() async {
    state = const AsyncLoading();
    final result = await _repo.seedDefaults();
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

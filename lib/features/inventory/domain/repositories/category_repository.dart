import '../../../../core/errors/result.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchCategories();
  Future<Result<Category>> getCategory(String id);
  Future<Result<Category>> createCategory(Category category);
  Future<Result<Category>> updateCategory(Category category);
  Future<Result<void>> deleteCategory(String id);
  Future<Result<void>> seedDefaults();
}

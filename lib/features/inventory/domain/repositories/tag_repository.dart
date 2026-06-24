import '../../../../core/errors/result.dart';
import '../entities/tag.dart';

abstract class TagRepository {
  Stream<List<Tag>> watchTags();
  Future<Result<Tag>> getTag(String id);
  Future<Result<Tag>> createTag(Tag tag);
  Future<Result<Tag>> updateTag(Tag tag);
  Future<Result<void>> deleteTag(String id);
  Future<Result<void>> setItemTags(String itemId, List<String> tagIds);
  Future<Result<List<Tag>>> getItemTags(String itemId);
}

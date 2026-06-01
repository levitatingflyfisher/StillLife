import '../../../../core/errors/result.dart';
import '../entities/policy.dart';

abstract class PolicyRepository {
  Stream<List<Policy>> watchAll();
  Future<Result<List<Policy>>> getByPropertyId(String propertyId);
  Future<Result<Policy>> create(Policy policy);
  Future<Result<Policy>> update(Policy policy);
  Future<Result<void>> delete(String id);
}

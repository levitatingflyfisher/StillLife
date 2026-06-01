import '../../../../core/errors/result.dart';
import '../entities/appraisal.dart';

/// Abstract repository for per-item market-value appraisals.
abstract class AppraisalRepository {
  /// Watches the non-deleted appraisals for a given item (newest first).
  Stream<List<Appraisal>> watchForItem(String itemId);

  /// Returns the most recent fresh (non-expired, non-deleted) appraisal for
  /// this item + mode, or null.
  Future<Appraisal?> getLatestByItemAndMode(String itemId, AppraisalMode mode);

  /// Cache-key lookup across items. Returns any fresh non-deleted appraisal
  /// matching `(itemModelKey, mode, countryCode)`.
  Future<Appraisal?> getLatestByCacheKey(
    String itemModelKey,
    AppraisalMode mode,
    String countryCode,
  );

  /// Inserts or replaces an appraisal row.
  Future<Result<Appraisal>> save(Appraisal a);

  /// Soft-deletes an appraisal by id.
  Future<Result<void>> delete(String id);
}

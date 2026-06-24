import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/database/database.dart' as db;
import '../../domain/entities/policy.dart';
import '../../domain/repositories/policy_repository.dart';

const _uuid = Uuid();

class PolicyRepositoryImpl implements PolicyRepository {
  final db.AppDatabase _db;

  PolicyRepositoryImpl(this._db);

  @override
  Stream<List<Policy>> watchAll() {
    return _db.policyDao.watchAll().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Result<List<Policy>>> getByPropertyId(String propertyId) async {
    try {
      final rows = await _db.policyDao.getByPropertyId(propertyId);
      return Success(rows.map(_toEntity).toList());
    } catch (e) {
      return Err(DatabaseFailure('Failed to get policies: $e'));
    }
  }

  @override
  Future<Result<Policy>> create(Policy policy) async {
    try {
      final now = DateTime.now();
      final id = policy.id.isEmpty ? _uuid.v4() : policy.id;
      await _db.policyDao.insertPolicy(
        db.PoliciesCompanion.insert(
          id: id,
          propertyId: policy.propertyId,
          provider: policy.provider,
          policyNumber: Value(policy.policyNumber),
          coverageAmount: Value(policy.coverageAmount),
          deductible: Value(policy.deductible),
          premium: Value(policy.premium),
          expiryDate: Value(policy.expiryDate),
          createdAt: now,
          modifiedAt: now,
        ),
      );
      final created = await _db.policyDao.getById(id);
      return Success(_toEntity(created!));
    } catch (e) {
      return Err(DatabaseFailure('Failed to create policy: $e'));
    }
  }

  @override
  Future<Result<Policy>> update(Policy policy) async {
    try {
      final now = DateTime.now();
      final ok = await _db.policyDao.updatePolicy(
        db.PoliciesCompanion(
          id: Value(policy.id),
          propertyId: Value(policy.propertyId),
          provider: Value(policy.provider),
          policyNumber: Value(policy.policyNumber),
          coverageAmount: Value(policy.coverageAmount),
          deductible: Value(policy.deductible),
          premium: Value(policy.premium),
          expiryDate: Value(policy.expiryDate),
          modifiedAt: Value(now),
        ),
      );
      if (!ok) return const Err(DatabaseFailure('Policy not found'));
      final updated = await _db.policyDao.getById(policy.id);
      return Success(_toEntity(updated!));
    } catch (e) {
      return Err(DatabaseFailure('Failed to update policy: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _db.policyDao.deletePolicy(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure('Failed to delete policy: $e'));
    }
  }

  Policy _toEntity(db.Policy row) => Policy(
    id: row.id,
    propertyId: row.propertyId,
    provider: row.provider,
    policyNumber: row.policyNumber,
    coverageAmount: row.coverageAmount,
    deductible: row.deductible,
    premium: row.premium,
    expiryDate: row.expiryDate,
    createdAt: row.createdAt,
  );
}

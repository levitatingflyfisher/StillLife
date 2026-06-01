import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/policy.dart';
import '../../domain/repositories/policy_repository.dart';

/// Reactive list of all policies.
final policiesProvider = StreamProvider<List<Policy>>((ref) {
  return ref.watch(policyRepositoryProvider).watchAll();
});

/// Policy CRUD controller.
final policyControllerProvider =
    StateNotifierProvider<PolicyController, AsyncValue<void>>((ref) {
      return PolicyController(ref.watch(policyRepositoryProvider));
    });

class PolicyController extends StateNotifier<AsyncValue<void>> {
  final PolicyRepository _repo;

  PolicyController(this._repo) : super(const AsyncData(null));

  Future<bool> add(Policy policy) async {
    state = const AsyncLoading();
    final result = await _repo.create(policy);
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

  Future<bool> edit(Policy policy) async {
    state = const AsyncLoading();
    final result = await _repo.update(policy);
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

  Future<bool> remove(String id) async {
    state = const AsyncLoading();
    final result = await _repo.delete(id);
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

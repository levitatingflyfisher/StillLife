import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/appraisal_providers.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../domain/entities/appraisal.dart';

/// AsyncNotifier managing appraisal state for a single item+mode pair.
/// Invoked by the AppraisalCard when the user taps a mode chip.
///
/// State shape:
///   AsyncData(Appraisal?) — null when no fresh cache and no request yet.
///   AsyncLoading         — request in flight.
///   AsyncError           — parse / network / validation failure.
class AppraisalController
    extends
        FamilyAsyncNotifier<Appraisal?, ({String itemId, AppraisalMode mode})> {
  @override
  Future<Appraisal?> build(({String itemId, AppraisalMode mode}) arg) {
    return ref
        .watch(appraisalRepositoryProvider)
        .getLatestByItemAndMode(arg.itemId, arg.mode);
  }

  /// Triggers a (cached-or-fresh) appraisal for the given item.
  Future<void> appraise(Item item, {bool forceRefresh = false}) async {
    state = const AsyncLoading();
    final svc = ref.read(appraiserServiceProvider);
    final res = await svc.appraise(item, arg.mode, forceRefresh: forceRefresh);
    res.when(
      success: (a) => state = AsyncData(a),
      failure: (f) => state = AsyncError(f, StackTrace.current),
    );
  }
}

final appraisalControllerProvider =
    AsyncNotifierProvider.family<
      AppraisalController,
      Appraisal?,
      ({String itemId, AppraisalMode mode})
    >(AppraisalController.new);

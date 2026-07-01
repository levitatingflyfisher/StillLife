import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../locations/presentation/controllers/location_controller.dart';
import '../../data/services/dashboard_aggregator.dart';

/// Lightweight stream that emits whenever items change — used to trigger
/// dashboard refresh without streaming entire item lists.
final _itemCountStreamProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.itemDao.watchAllItems().map((l) => l.length);
});

/// Dashboard summary data. All monetary figures are integer cents.
class DashboardSummary {
  final int totalItems;
  final int totalCurrentValueCents;
  final int totalReplacementCostCents;
  final int totalAcquisitionCostCents;
  final Map<String, int> valueCentsByRoom;
  final Map<String, int> valueCentsByCategory;
  final int totalDepreciationCents;
  final List<({String name, int valueCents})> topItems;
  final int? totalCoverageAmountCents;

  const DashboardSummary({
    this.totalItems = 0,
    this.totalCurrentValueCents = 0,
    this.totalReplacementCostCents = 0,
    this.totalAcquisitionCostCents = 0,
    this.valueCentsByRoom = const {},
    this.valueCentsByCategory = const {},
    this.totalDepreciationCents = 0,
    this.topItems = const [],
    this.totalCoverageAmountCents,
  });
}

/// Provides a reactive dashboard summary.
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  // Watch lightweight streams so any item/room CRUD triggers a refresh.
  ref.watch(_itemCountStreamProvider);
  ref.watch(roomsProvider);

  final db = ref.read(databaseProvider);
  final aggregator = DashboardAggregator(db);

  final totalItems = await db.itemDao.countItems();
  final totalValueCents = await db.itemDao.getTotalValueCents();
  final totalReplacementCents = await db.itemDao.getTotalReplacementCostCents();
  final totalAcquisitionCents = await db.itemDao.getTotalAcquisitionCostCents();
  final valueCentsByRoom = await aggregator.getValueCentsByRoom();
  final valueCentsByCategory = await aggregator.getValueCentsByCategory();
  final totalDepreciationCents = await aggregator.getTotalDepreciationCents();
  final topItems = await aggregator.getTopItemsByValue(5);

  // Sum coverage from all policies
  final policies = await db.policyDao.getAll();
  final totalCoverageCents = policies.isEmpty
      ? null
      : policies.fold(0, (int sum, p) => sum + (p.coverageAmountCents ?? 0));

  return DashboardSummary(
    totalItems: totalItems,
    totalCurrentValueCents: totalValueCents,
    totalReplacementCostCents: totalReplacementCents,
    totalAcquisitionCostCents: totalAcquisitionCents,
    valueCentsByRoom: valueCentsByRoom,
    valueCentsByCategory: valueCentsByCategory,
    totalDepreciationCents: totalDepreciationCents,
    topItems: topItems,
    totalCoverageAmountCents: totalCoverageCents,
  );
});

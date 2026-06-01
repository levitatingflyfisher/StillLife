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

/// Dashboard summary data.
class DashboardSummary {
  final int totalItems;
  final double totalCurrentValue;
  final double totalReplacementCost;
  final double totalAcquisitionCost;
  final Map<String, double> valueByRoom;
  final Map<String, double> valueByCategory;
  final double totalDepreciation;
  final List<({String name, double value})> topItems;
  final double? totalCoverageAmount;

  const DashboardSummary({
    this.totalItems = 0,
    this.totalCurrentValue = 0.0,
    this.totalReplacementCost = 0.0,
    this.totalAcquisitionCost = 0.0,
    this.valueByRoom = const {},
    this.valueByCategory = const {},
    this.totalDepreciation = 0.0,
    this.topItems = const [],
    this.totalCoverageAmount,
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
  final totalValue = await db.itemDao.getTotalValue();
  final totalReplacement = await db.itemDao.getTotalReplacementCost();
  final totalAcquisition = await db.itemDao.getTotalAcquisitionCost();
  final valueByRoom = await aggregator.getValueByRoom();
  final valueByCategory = await aggregator.getValueByCategory();
  final totalDepreciation = await aggregator.getTotalDepreciation();
  final topItems = await aggregator.getTopItemsByValue(5);

  // Sum coverage from all policies
  final policies = await db.policyDao.getAll();
  final totalCoverage = policies.isEmpty
      ? null
      : policies.fold(0.0, (sum, p) => sum + (p.coverageAmount ?? 0));

  return DashboardSummary(
    totalItems: totalItems,
    totalCurrentValue: totalValue,
    totalReplacementCost: totalReplacement,
    totalAcquisitionCost: totalAcquisition,
    valueByRoom: valueByRoom,
    valueByCategory: valueByCategory,
    totalDepreciation: totalDepreciation,
    topItems: topItems,
    totalCoverageAmount: totalCoverage,
  );
});

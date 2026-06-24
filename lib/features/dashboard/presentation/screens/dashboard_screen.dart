import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../../../inventory/presentation/controllers/quantity_controller.dart';
import '../../../loans/presentation/controllers/loan_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/coverage_gap_widget.dart';
import '../widgets/depreciation_summary_card.dart';
import '../widgets/room_value_chart.dart';
import '../widgets/stat_card.dart';
import '../widgets/top_items_list.dart';
import '../widgets/value_breakdown_chart.dart';
import '../widgets/warranty_expiry_widget.dart';
import '../widgets/upcoming_maintenance_widget.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/items_by_month_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Still Life'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search items',
            onPressed: () => context.pushNamed('search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
        },
        child: summaryAsync.when(
          data: (summary) => ListView(
            padding: OhSpacing.insetMd,
            children: [
              // Quick stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Items',
                      value: summary.totalItems.toString(),
                      icon: Icons.inventory_2_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Total Value',
                      value: summary.totalCurrentValue.toCurrency(),
                      icon: Icons.account_balance_wallet_outlined,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Replacement Cost',
                      value: summary.totalReplacementCost.toCurrency(),
                      icon: Icons.price_change_outlined,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Acquisition Cost',
                      value: summary.totalAcquisitionCost.toCurrency(),
                      icon: Icons.shopping_cart_outlined,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OhSpacing.lg),

              // Items on Loan
              ListTile(
                leading: const Icon(Icons.swap_horiz_outlined),
                title: const Text('Items on Loan'),
                subtitle: Consumer(
                  builder: (context, ref, _) {
                    final count =
                        ref.watch(activeLoansProvider).valueOrNull?.length ?? 0;
                    return Text(
                      count == 0
                          ? 'Nothing out'
                          : '$count item${count == 1 ? '' : 's'} out',
                    );
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.goNamed('allLoans'),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final lowStock =
                      ref.watch(lowStockItemsProvider).valueOrNull ?? [];
                  if (lowStock.isEmpty) return const SizedBox.shrink();
                  return ListTile(
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: const Text('Low Stock'),
                    subtitle: Text(
                      '${lowStock.length} item${lowStock.length == 1 ? '' : 's'} running low',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed('lowStock'),
                  );
                },
              ),
              const SizedBox(height: OhSpacing.lg),

              // Value by Category
              if (summary.valueByCategory.isNotEmpty) ...[
                Text('Value by Category', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ValueBreakdownChart(data: summary.valueByCategory),
                ),
                const SizedBox(height: OhSpacing.lg),
              ],

              // Depreciation Summary
              if (summary.totalAcquisitionCost > 0) ...[
                DepreciationSummaryCard(
                  totalOriginalValue: summary.totalAcquisitionCost,
                  totalCurrentValue: summary.totalCurrentValue,
                  totalDepreciation: summary.totalDepreciation,
                ),
                const SizedBox(height: OhSpacing.lg),
              ],

              // Top Items by Value
              if (summary.topItems.isNotEmpty) ...[
                Text('Top Items by Value', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Card(
                  child: TopItemsList(
                    items: summary.topItems
                        .asMap()
                        .entries
                        .map(
                          (e) => TopItem(
                            rank: e.key + 1,
                            name: e.value.name,
                            value: e.value.value,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: OhSpacing.lg),
              ],

              // Value by Room
              if (summary.valueByRoom.isNotEmpty) ...[
                Text('Value by Room', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: RoomValueChart(data: summary.valueByRoom),
                ),
                const SizedBox(height: OhSpacing.lg),
              ],

              // Insurance Coverage
              if (summary.totalCoverageAmount != null) ...[
                Text('Insurance Coverage', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: OhSpacing.insetMd,
                    child: CoverageGapWidget(
                      totalValue: summary.totalCurrentValue,
                      coverageAmount: summary.totalCoverageAmount,
                    ),
                  ),
                ),
                const SizedBox(height: OhSpacing.lg),
              ],

              // Warranty Expiry
              const WarrantyExpiryWidget(),
              const SizedBox(height: OhSpacing.md),

              // Upcoming Maintenance
              const UpcomingMaintenanceWidget(),
              const SizedBox(height: OhSpacing.lg),

              // Recent Activity
              const RecentActivityWidget(),
              const SizedBox(height: OhSpacing.lg),

              // Items Added by Month
              const ItemsByMonthChart(),
              const SizedBox(height: OhSpacing.lg),

              // Quick Actions
              Text('Quick Actions', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                    onPressed: () => context.pushNamed('addItem'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export'),
                    onPressed: () => context.pushNamed('reports'),
                  ),
                ],
              ),

              // Empty state
              if (summary.totalItems == 0) ...[
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withAlpha(80),
                      ),
                      const SizedBox(height: OhSpacing.md),
                      Text(
                        'No items yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      const SizedBox(height: OhSpacing.sm),
                      Text(
                        'Add items manually or record a video\nwalkthrough to get started.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                      const SizedBox(height: OhSpacing.lg),
                      FilledButton.icon(
                        onPressed: () => context.pushNamed('addItem'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Item'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

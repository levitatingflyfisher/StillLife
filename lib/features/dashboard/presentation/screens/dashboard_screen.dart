import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../inventory/presentation/controllers/quantity_controller.dart';
import '../../../loans/presentation/controllers/loan_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/coverage_gap_widget.dart';
import '../widgets/depreciation_summary_card.dart';
import '../widgets/room_value_chart.dart';
import '../widgets/stat_grid.dart';
import '../widgets/top_items_list.dart';
import '../widgets/value_breakdown_chart.dart';
import '../widgets/warranty_expiry_widget.dart';
import '../widgets/upcoming_maintenance_widget.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/items_by_month_chart.dart';
import 'package:still_life/core/widgets/failure_feedback.dart';
import '../../../settings/presentation/widgets/theme_toggle_action.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Still Life'),
        actions: [OhBarActions(children: [
          const ThemeToggleAction(),
          OhBarAction(
            icon: Icons.search,
            label: 'Search',
            onPressed: () => context.pushNamed('search'),
          ),
          OhBarAction(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onPressed: () => context.pushNamed('settings'),
          ),
        ])],
      ),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
        },
        child: summaryAsync.when(
          data: (summary) => ListView(
            padding: OhSpacing.insetMd,
            children: [
              // Unfinished backup setup (recovery words not saved or not
              // checked) gets a persistent, dismissable line: a catalogue
              // on one phone is the step most dangerous to skip.
              const BackupSetupReminder(),
              // Quick stats
              StatGrid(summary: summary),
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
              if (summary.valueCentsByCategory.isNotEmpty) ...[
                Text('Value by Category', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ValueBreakdownChart(dataCents: summary.valueCentsByCategory),
                ),
                const SizedBox(height: OhSpacing.lg),
              ],

              // Depreciation Summary
              if (summary.totalAcquisitionCostCents > 0) ...[
                DepreciationSummaryCard(
                  totalOriginalValueCents: summary.totalAcquisitionCostCents,
                  totalCurrentValueCents: summary.totalCurrentValueCents,
                  totalDepreciationCents: summary.totalDepreciationCents,
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
                            valueCents: e.value.valueCents,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: OhSpacing.lg),
              ],

              // Value by Room
              if (summary.valueCentsByRoom.isNotEmpty) ...[
                Text('Value by Room', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: RoomValueChart(dataCents: summary.valueCentsByRoom),
                ),
                const SizedBox(height: OhSpacing.lg),
              ],

              // Insurance Coverage
              if (summary.totalCoverageAmountCents != null) ...[
                Text('Insurance Coverage', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: OhSpacing.insetMd,
                    child: CoverageGapWidget(
                      totalValueCents: summary.totalCurrentValueCents,
                      coverageAmountCents: summary.totalCoverageAmountCents,
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
                        color: theme.colorScheme.onSurfaceVariant,
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
                          color: theme.colorScheme.onSurfaceVariant,
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
          error: (e, st) => loadFailure(
            e,
            st,
            title: "Couldn’t load your dashboard",
            onRetry: () => ref.invalidate(dashboardSummaryProvider),
          ),
        ),
      ),
      ),
    );
  }
}

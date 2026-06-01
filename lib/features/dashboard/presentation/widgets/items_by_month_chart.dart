import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/services/dashboard_aggregator.dart';

final _itemsByMonthProvider = FutureProvider<List<({String label, int count})>>(
  (ref) async {
    final db = ref.watch(databaseProvider);
    return DashboardAggregator(db).getItemsByMonth();
  },
);

class ItemsByMonthChart extends ConsumerWidget {
  const ItemsByMonthChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_itemsByMonthProvider);
    final theme = Theme.of(context);

    return dataAsync.when(
      data: (months) {
        final total = months.fold(0, (s, m) => s + m.count);
        if (total == 0) return const SizedBox.shrink();

        final maxCount = months
            .map((m) => m.count)
            .reduce((a, b) => a > b ? a : b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items Added by Month', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: (maxCount + 1).toDouble(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= months.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            months[idx].label,
                            style: theme.textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: months.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.count.toDouble(),
                          color: theme.colorScheme.primary,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

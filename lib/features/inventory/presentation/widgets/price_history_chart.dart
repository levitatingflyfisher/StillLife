import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/repository_providers.dart';

class PriceHistoryChart extends ConsumerWidget {
  final String itemId;

  const PriceHistoryChart({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(priceHistoryProvider(itemId));
    final theme = Theme.of(context);

    return historyAsync.when(
      data: (entries) {
        // Need at least 2 points to draw a line.
        if (entries.length < 2) return const SizedBox.shrink();

        // Entries arrive newest-first from the DAO; reverse for chronological order.
        final sorted = entries.reversed.toList();
        final minDate = sorted.first.recordedAt.millisecondsSinceEpoch
            .toDouble();
        final maxDate = sorted.last.recordedAt.millisecondsSinceEpoch
            .toDouble();
        final prices = sorted.map((e) => e.price).toList();
        final minPrice = prices.reduce((a, b) => a < b ? a : b);
        final maxPrice = prices.reduce((a, b) => a > b ? a : b);
        final pricePad = (maxPrice - minPrice) * 0.1 + 0.01;

        final spots = sorted
            .map(
              (e) => FlSpot(
                e.recordedAt.millisecondsSinceEpoch.toDouble(),
                e.price,
              ),
            )
            .toList();

        final color = theme.colorScheme.primary;
        final currencyFmt = NumberFormat.simpleCurrency();
        final dateFmt = DateFormat.MMMd();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Value History',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  minY: minPrice - pricePad,
                  maxY: maxPrice + pricePad,
                  minX: minDate,
                  maxX: maxDate,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 64,
                        getTitlesWidget: (value, meta) => Text(
                          currencyFmt.format(value),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: (maxDate - minDate) / 2,
                        getTitlesWidget: (value, meta) {
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            value.toInt(),
                          );
                          return Text(
                            dateFmt.format(dt),
                            style: theme.textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withAlpha(30),
                      ),
                    ),
                  ],
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

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CostComparison {
  final String categoryName;
  final double acquisitionCost;
  final double currentValue;
  final double replacementCost;

  const CostComparison({
    required this.categoryName,
    required this.acquisitionCost,
    required this.currentValue,
    required this.replacementCost,
  });
}

class CostComparisonChart extends StatelessWidget {
  final List<CostComparison> data;

  const CostComparisonChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(120),
          ),
        ),
      );
    }

    final acquisitionColor = theme.colorScheme.primary;
    final currentColor = theme.colorScheme.secondary;
    final replacementColor = theme.colorScheme.tertiary;

    final allValues = data.expand(
      (e) => [e.acquisitionCost, e.currentValue, e.replacementCost],
    );
    final maxValue = allValues.fold(0.0, (max, v) => v > max ? v : max);

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue * 1.15,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          data[index].categoryName,
                          style: theme.textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: data.asMap().entries.map((e) {
                final index = e.key;
                final item = e.value;
                return BarChartGroupData(
                  x: index,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: item.acquisitionCost,
                      color: acquisitionColor,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: item.currentValue,
                      color: currentColor,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: item.replacementCost,
                      color: replacementColor,
                      width: 12,
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: acquisitionColor, label: 'Acquisition'),
            const SizedBox(width: 16),
            _LegendItem(color: currentColor, label: 'Current'),
            const SizedBox(width: 16),
            _LegendItem(color: replacementColor, label: 'Replacement'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

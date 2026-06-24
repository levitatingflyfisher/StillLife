import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/extensions/currency_extensions.dart';

class ValueBreakdownChart extends StatelessWidget {
  final Map<String, double> data;

  const ValueBreakdownChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(120),
          ),
        ),
      );
    }

    final total = entries.fold(0.0, (sum, e) => sum + e.value);
    final colors = _generateColors(entries.length, theme.colorScheme);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: entries.asMap().entries.map((e) {
                final index = e.key;
                final entry = e.value;
                final percentage = (entry.value / total * 100);
                return PieChartSectionData(
                  color: colors[index],
                  value: entry.value,
                  title: percentage >= 5
                      ? '${percentage.toStringAsFixed(0)}%'
                      : '',
                  radius: 60,
                  titleStyle: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.take(6).map((e) {
              final index = e.key;
              final entry = e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: theme.textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      entry.value.toCompactCurrency(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<Color> _generateColors(int count, ColorScheme scheme) {
    final baseColors = [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
      scheme.primaryContainer,
      scheme.secondaryContainer,
      scheme.tertiaryContainer,
    ];

    if (count <= baseColors.length) return baseColors.take(count).toList();

    return List.generate(count, (i) {
      if (i < baseColors.length) return baseColors[i];
      return HSLColor.fromAHSL(
        1.0,
        (i * 360 / count) % 360,
        0.6,
        0.5,
      ).toColor();
    });
  }
}

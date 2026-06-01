import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../../core/extensions/currency_extensions.dart';

class DepreciationSummaryCard extends StatelessWidget {
  final double totalOriginalValue;
  final double totalCurrentValue;
  final double totalDepreciation;

  const DepreciationSummaryCard({
    super.key,
    required this.totalOriginalValue,
    required this.totalCurrentValue,
    required this.totalDepreciation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final remainingPercent = totalOriginalValue > 0
        ? (totalCurrentValue / totalOriginalValue).clamp(0.0, 1.0)
        : 0.0;
    final depreciationPercent = totalOriginalValue > 0
        ? (totalDepreciation / totalOriginalValue * 100).clamp(0.0, 100.0)
        : 0.0;

    final Color indicatorColor;
    if (remainingPercent > 0.7) {
      indicatorColor = OhColors.sage600;
    } else if (remainingPercent >= 0.4) {
      indicatorColor = OhColors.amber400;
    } else {
      indicatorColor = OhColors.red500;
    }

    return Card(
      child: Padding(
        padding: OhSpacing.insetMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_down,
                  size: 20,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
                const SizedBox(width: OhSpacing.sm),
                Text('Depreciation Summary', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: OhSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Depreciation',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                Text(
                  totalDepreciation.toCurrency(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: indicatorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: OhSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Depreciation Rate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                Text(
                  '${depreciationPercent.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: OhSpacing.md),
            Text(
              'Value Remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: OhSpacing.sm),
            ClipRRect(
              borderRadius: OhRadii.sm,
              child: LinearProgressIndicator(
                value: remainingPercent,
                minHeight: 8,
                backgroundColor: indicatorColor.withAlpha(40),
                valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              ),
            ),
            const SizedBox(height: OhSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  totalCurrentValue.toCurrency(),
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  totalOriginalValue.toCurrency(),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

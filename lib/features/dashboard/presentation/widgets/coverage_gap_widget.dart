import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../../core/extensions/currency_extensions.dart';

class CoverageGapWidget extends StatelessWidget {
  /// Integer cents throughout (see core/utils/money.dart).
  final int totalValueCents;
  final int? coverageAmountCents;

  const CoverageGapWidget({
    super.key,
    required this.totalValueCents,
    this.coverageAmountCents,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (coverageAmountCents == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha(80),
            ),
            const SizedBox(height: 8),
            Text(
              'No policy configured',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
      );
    }

    final percentage = totalValueCents > 0
        ? (coverageAmountCents! / totalValueCents).clamp(0.0, 1.0)
        : 0.0;
    final percentDisplay = (percentage * 100).toStringAsFixed(0);

    final Color indicatorColor;
    if (percentage > 0.8) {
      indicatorColor = OhColors.sage600;
    } else if (percentage >= 0.5) {
      indicatorColor = OhColors.amber400;
    } else {
      indicatorColor = OhColors.red500;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 10,
                  backgroundColor: indicatorColor.withAlpha(40),
                  valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentDisplay%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: indicatorColor,
                    ),
                  ),
                  Text(
                    'covered',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Coverage: ${coverageAmountCents!.centsToCurrency()}',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          'Total Value: ${totalValueCents.centsToCurrency()}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

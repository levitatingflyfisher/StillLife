import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../../services/ml/analysis_provider.dart';

/// Says plainly what this analysis costs before the calls run: how many
/// frames survived the gate (= how many analysis calls) and whose compute
/// pays for them. Call counts and tier names only — never invented
/// dollar figures.
class AnalysisCostNotice extends StatelessWidget {
  final int calls;
  final AnalysisTier tier;

  const AnalysisCostNotice({
    super.key,
    required this.calls,
    required this.tier,
  });

  String get _posture => switch (tier) {
    AnalysisTier.localLlm => 'Local (Ollama): free, slower',
    AnalysisTier.cloudApi => 'Cloud (your key): calls run on your API key',
    AnalysisTier.hosted => 'Hosted: calls run on your Still Life account',
    AnalysisTier.onDevice => 'On-device',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: OhRadii.md,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: OhSpacing.sm),
          Expanded(
            child: Text(
              '~$calls analysis calls · $_posture',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

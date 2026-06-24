import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/appraisal_providers.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../domain/entities/appraisal.dart';
import 'appraise_sheet.dart';

/// A card on the item detail screen that surfaces three market-value chips
/// (resale / replace-new / replace-equivalent). Tap a chip → open
/// [AppraiseSheet] to run or refresh the estimate.
class AppraisalCard extends ConsumerWidget {
  final Item item;
  const AppraisalCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: OhSpacing.insetMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.query_stats, color: theme.colorScheme.primary),
                const SizedBox(width: OhSpacing.sm),
                Text('Market Value', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppraisalMode.values
                  .map((mode) => _ModeChip(item: item, mode: mode))
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends ConsumerWidget {
  final Item item;
  final AppraisalMode mode;
  const _ModeChip({required this.item, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(
      latestAppraisalProvider((itemId: item.id, mode: mode)),
    );
    final label = latest.when(
      data: (a) => a == null || !a.hasData
          ? '${mode.label} —'
          : '${mode.label}  ${_fmt(a.value, a.currency)}',
      loading: () => '${mode.label}…',
      error: (_, _) => '${mode.label} —',
    );
    return InputChip(label: Text(label), onPressed: () => _openSheet(context));
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AppraiseSheet(item: item, mode: mode),
    );
  }

  String _fmt(double value, String currency) {
    final f = NumberFormat.simpleCurrency(name: currency);
    return f.format(value);
  }
}

import 'package:flutter/material.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../controllers/dashboard_controller.dart';
import 'stat_card.dart';

/// The four headline figures. One foreground colour for all of them: none
/// of these is an error, and error red is kept for errors
/// (mind-in-mind-02, design-for-hackers-01). Acquisition Cost used to be
/// painted `colorScheme.error`.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Items',
                value: summary.totalItems.toString(),
                icon: Icons.inventory_2_outlined,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Total Value',
                value: summary.totalCurrentValueCents.centsToCurrency(),
                icon: Icons.account_balance_wallet_outlined,
                color: theme.colorScheme.onSurface,
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
                value: summary.totalReplacementCostCents.centsToCurrency(),
                icon: Icons.price_change_outlined,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Acquisition Cost',
                value: summary.totalAcquisitionCostCents.centsToCurrency(),
                icon: Icons.shopping_cart_outlined,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

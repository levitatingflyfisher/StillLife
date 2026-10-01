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
    final ink = theme.colorScheme.onSurface;
    final cards = [
      StatCard(
        title: 'Total Items',
        value: summary.totalItems.toString(),
        icon: Icons.inventory_2_outlined,
        color: ink,
      ),
      StatCard(
        title: 'Total Value',
        value: summary.totalCurrentValueCents.centsToCurrency(),
        icon: Icons.account_balance_wallet_outlined,
        color: ink,
      ),
      StatCard(
        title: 'Replacement Cost',
        value: summary.totalReplacementCostCents.centsToCurrency(),
        icon: Icons.price_change_outlined,
        color: ink,
      ),
      StatCard(
        title: 'Acquisition Cost',
        value: summary.totalAcquisitionCostCents.centsToCurrency(),
        icon: Icons.shopping_cart_outlined,
        color: ink,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two tiles a row while a half-width tile still has room for its
        // title at this text size; one a row past that, so large text wraps
        // words instead of breaking them (audit finding 7).
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final twoUp = constraints.maxWidth >= 230 * scale;
        if (!twoUp) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                cards[i],
              ],
            ],
          );
        }
        Widget row(StatCard a, StatCard b) => IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: a),
                  const SizedBox(width: 12),
                  Expanded(child: b),
                ],
              ),
            );
        return Column(
          children: [
            row(cards[0], cards[1]),
            const SizedBox(height: 12),
            row(cards[2], cards[3]),
          ],
        );
      },
    );
  }
}

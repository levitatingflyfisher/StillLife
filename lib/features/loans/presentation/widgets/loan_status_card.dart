import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/loan.dart';

/// Card showing the current loan status of an item.
///
/// Displays active-loan details (borrower, dates, overdue/due-soon badge)
/// or an "Lend this item" button when no loan is active.
class LoanStatusCard extends StatelessWidget {
  const LoanStatusCard({
    super.key,
    required this.loan,
    required this.onMarkReturned,
    required this.onEdit,
    required this.onLend,
  });

  /// The active (unreturned) loan, or null if the item is not on loan.
  final Loan? loan;
  final VoidCallback onMarkReturned;
  final VoidCallback onEdit;
  final VoidCallback onLend;

  static final _dateFmt = DateFormat.yMMMd();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: OhSpacing.insetMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: OhSpacing.sm),
            if (loan != null)
              ..._buildActiveLoan(context, loan!, theme, colorScheme)
            else
              ..._buildNoLoan(theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActiveLoan(
    BuildContext context,
    Loan loan,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return [
      Text(loan.borrowerName, style: theme.textTheme.titleMedium),
      const SizedBox(height: OhSpacing.xs),
      Text(
        'Since: ${_dateFmt.format(loan.createdAt)}',
        style: theme.textTheme.bodySmall,
      ),
      if (loan.expectedReturnDate != null) ...[
        const SizedBox(height: OhSpacing.xs),
        Text(
          'Due: ${_dateFmt.format(loan.expectedReturnDate!)}',
          style: theme.textTheme.bodySmall,
        ),
      ],
      if (loan.isOverdue || loan.isDueSoon) ...[
        const SizedBox(height: OhSpacing.sm),
        if (loan.isOverdue)
          Chip(
            label: const Text('Overdue'),
            backgroundColor: colorScheme.errorContainer,
            labelStyle: TextStyle(color: colorScheme.onErrorContainer),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          )
        else
          Chip(
            label: const Text('Due Soon'),
            backgroundColor: colorScheme.tertiaryContainer,
            labelStyle: TextStyle(color: colorScheme.onTertiaryContainer),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
      ],
      const SizedBox(height: 12),
      // Wrap (not Row) so the action buttons fall to a second line instead of
      // overflowing when large accessibility text widens them past the card.
      Wrap(
        alignment: WrapAlignment.end,
        spacing: OhSpacing.sm,
        runSpacing: OhSpacing.xs,
        children: [
          TextButton(onPressed: onEdit, child: const Text('Edit')),
          FilledButton(
            onPressed: onMarkReturned,
            child: const Text('Mark Returned'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildNoLoan(ThemeData theme) {
    return [
      OutlinedButton(onPressed: onLend, child: const Text('Lend this item')),
    ];
  }
}

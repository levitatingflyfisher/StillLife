import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/loan.dart';
import '../controllers/loan_controller.dart';

class AllLoansScreen extends ConsumerWidget {
  const AllLoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(activeLoansProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('On Loan')),
      body: loansAsync.when(
        data: (loans) {
          if (loans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items on loan',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            );
          }

          final widgets = _buildList(loans, context, ref);
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: widgets,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

List<Widget> _buildList(List<Loan> loans, BuildContext context, WidgetRef ref) {
  final overdue = loans.where((l) => l.isOverdue).toList();
  final dueSoon = loans.where((l) => l.isDueSoon).toList();
  final upcoming = loans
      .where(
        (l) => !l.isOverdue && !l.isDueSoon && l.expectedReturnDate != null,
      )
      .toList();
  final noDueDate = loans.where((l) => l.expectedReturnDate == null).toList();

  final widgets = <Widget>[];

  void addSection(String header, List<Loan> section, {Color? headerColor}) {
    if (section.isEmpty) return;
    widgets.add(_SectionHeader(title: header, color: headerColor));
    widgets.addAll(
      section.map(
        (l) => _LoanTile(
          loan: l,
          onMarkReturned: () =>
              ref.read(loanControllerProvider.notifier).markReturned(l.id),
        ),
      ),
    );
  }

  addSection(
    'Overdue',
    overdue,
    headerColor: Theme.of(context).colorScheme.error,
  );
  addSection('Due Soon', dueSoon);
  addSection('Upcoming', upcoming);
  addSection('No Due Date', noDueDate);

  return widgets;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.color});

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _LoanTile extends StatelessWidget {
  const _LoanTile({required this.loan, required this.onMarkReturned});

  final Loan loan;
  final VoidCallback onMarkReturned;

  static final _dateFmt = DateFormat.yMMMd();

  @override
  Widget build(BuildContext context) {
    final dueText = loan.expectedReturnDate != null
        ? ' · Due ${_dateFmt.format(loan.expectedReturnDate!)}'
        : '';

    return ListTile(
      title: Text(loan.itemName),
      subtitle: Text('${loan.borrowerName}$dueText'),
      trailing: IconButton(
        icon: const Icon(Icons.check_circle_outline),
        tooltip: 'Mark returned',
        onPressed: onMarkReturned,
      ),
    );
  }
}

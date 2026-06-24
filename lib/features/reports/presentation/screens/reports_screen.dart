import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../../core/extensions/currency_extensions.dart';
import '../controllers/export_controller.dart';
import '../controllers/policy_controller.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: summaryAsync.when(
        data: (summary) {
          final policiesAsync = ref.watch(policiesProvider);
          return ListView(
            padding: OhSpacing.insetMd,
            children: [
              // Financial Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Overview',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: OhSpacing.md),
                      _SummaryRow(
                        label: 'Total Items',
                        value: summary.totalItems.toString(),
                      ),
                      _SummaryRow(
                        label: 'Current Value',
                        value: summary.totalCurrentValue.toCurrency(),
                        isHighlighted: true,
                      ),
                      _SummaryRow(
                        label: 'Replacement Cost',
                        value: summary.totalReplacementCost.toCurrency(),
                      ),
                      _SummaryRow(
                        label: 'Acquisition Cost',
                        value: summary.totalAcquisitionCost.toCurrency(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: OhSpacing.md),

              const SizedBox(height: OhSpacing.md),

              // Insurance Policies Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Insurance Policies',
                            style: theme.textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () => context.pushNamed('policies'),
                            child: const Text('Manage'),
                          ),
                        ],
                      ),
                      const SizedBox(height: OhSpacing.sm),
                      policiesAsync.when(
                        data: (policies) {
                          if (policies.isEmpty) {
                            return Text(
                              'No policies added yet. Add a policy to track your coverage gap.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  150,
                                ),
                              ),
                            );
                          }
                          final total = policies.fold<double>(
                            0,
                            (s, p) => s + (p.coverageAmount ?? 0),
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SummaryRow(
                                label: 'Policies',
                                value: policies.length.toString(),
                              ),
                              _SummaryRow(
                                label: 'Total coverage',
                                value: total.toCurrency(),
                                isHighlighted: true,
                              ),
                              if (policies.any((p) => p.isExpired))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber,
                                        color: theme.colorScheme.error,
                                        size: 16,
                                      ),
                                      const SizedBox(width: OhSpacing.xs),
                                      Text(
                                        '${policies.where((p) => p.isExpired).length} expired',
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const Text('Failed to load policies'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: OhSpacing.md),

              // Export options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Export Data', style: theme.textTheme.titleLarge),
                      const SizedBox(height: OhSpacing.md),
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: const Text('Insurance Report (PDF)'),
                        subtitle: const Text(
                          'Full inventory report with photos and values',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _exportPdf(context, ref),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text('Export as JSON'),
                        subtitle: const Text(
                          'Machine-readable export for backup/import',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _exportJson(context, ref),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.table_chart),
                        title: const Text('Export as CSV'),
                        subtitle: const Text('Spreadsheet-compatible format'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _exportCsv(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: OhSpacing.md),

              // Import
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Import Data', style: theme.textTheme.titleLarge),
                      const SizedBox(height: OhSpacing.md),
                      ListTile(
                        leading: const Icon(Icons.file_upload),
                        title: const Text('Import from JSON'),
                        subtitle: const Text(
                          'Restore from a Still Life backup file',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _importJson(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(exportControllerProvider.notifier)
        .exportPdf();
    if (context.mounted) {
      if (result != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF report ready')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF generation failed')));
      }
    }
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(exportControllerProvider.notifier)
        .exportJson();
    if (context.mounted) {
      if (result != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('JSON export ready')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export cancelled or failed')),
        );
      }
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(exportControllerProvider.notifier)
        .exportCsv();
    if (context.mounted) {
      if (result != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('CSV export ready')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export cancelled or failed')),
        );
      }
    }
  }

  Future<void> _importJson(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(exportControllerProvider.notifier)
        .importJson();
    if (result == null || !context.mounted) return;

    result.when(
      success: (summary) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${summary.totalRecords} records '
              '(${summary.items} items, ${summary.categories} categories, '
              '${summary.rooms} rooms)',
            ),
          ),
        );
        // Refresh dashboard
        ref.invalidate(dashboardSummaryProvider);
      },
      failure: (f) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: ${f.message}')));
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
          Text(
            value,
            style: isHighlighted
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }
}

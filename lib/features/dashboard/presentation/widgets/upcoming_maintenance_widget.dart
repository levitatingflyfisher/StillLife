import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../maintenance/presentation/controllers/maintenance_controller.dart';

class UpcomingMaintenanceWidget extends ConsumerWidget {
  const UpcomingMaintenanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(upcomingMaintenanceProvider);
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d, yyyy');

    return Card(
      child: Padding(
        padding: OhSpacing.insetMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: OhSpacing.sm),
                Text(
                  'Upcoming Maintenance',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No upcoming maintenance.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      const SizedBox(height: OhSpacing.sm),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Entry'),
                        onPressed: () => context.pushNamed('addMaintenance'),
                      ),
                    ],
                  );
                }
                final now = DateTime.now();
                final displayed = logs.take(5).toList();
                return Column(
                  children: [
                    ...displayed.map((log) {
                      final due = log.nextDueAt!;
                      final diff = due.difference(now).inDays;
                      final chipColor = diff < 0
                          ? theme.colorScheme.error
                          : diff <= 30
                          ? OhColors.amber400
                          : OhColors.sage600;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          log.title,
                          style: theme.textTheme.bodyMedium,
                        ),
                        trailing: Chip(
                          label: Text(
                            diff < 0 ? 'Overdue' : 'Due ${fmt.format(due)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                          backgroundColor: chipColor,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onTap: () => context.pushNamed('maintenance'),
                      );
                    }),
                    const SizedBox(height: OhSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.build, size: 16),
                        label: const Text('Log Maintenance'),
                        onPressed: () => context.pushNamed('addMaintenance'),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

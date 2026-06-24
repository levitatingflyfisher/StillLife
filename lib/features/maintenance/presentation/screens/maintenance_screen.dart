import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../../domain/entities/maintenance_log.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(maintenanceLogsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Log')),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No maintenance logs yet.',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Log Maintenance'),
                    onPressed: () => context.pushNamed('addMaintenance'),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final upcoming =
              logs
                  .where(
                    (l) => l.nextDueAt != null && l.nextDueAt!.isAfter(now),
                  )
                  .toList()
                ..sort((a, b) => a.nextDueAt!.compareTo(b.nextDueAt!));
          final past = logs
              .where((l) => l.nextDueAt == null || !l.nextDueAt!.isAfter(now))
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (upcoming.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Upcoming',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                ...upcoming.map(
                  (log) => _MaintenanceTile(
                    log: log,
                    onEdit: () => context.pushNamed(
                      'editMaintenance',
                      pathParameters: {'logId': log.id},
                      extra: log,
                    ),
                    onDelete: () => _confirmDelete(context, ref, log),
                  ),
                ),
                const Divider(height: 1, indent: 16),
              ],
              if (past.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Past',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                ),
                ...past.map(
                  (log) => _MaintenanceTile(
                    log: log,
                    onEdit: () => context.pushNamed(
                      'editMaintenance',
                      pathParameters: {'logId': log.id},
                      extra: log,
                    ),
                    onDelete: () => _confirmDelete(context, ref, log),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('addMaintenance'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MaintenanceLog log,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Remove "${log.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(maintenanceControllerProvider.notifier).remove(log.id);
    }
  }
}

class _MaintenanceTile extends StatelessWidget {
  final MaintenanceLog log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaintenanceTile({
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d, yyyy');
    final now = DateTime.now();

    Color chipColor() {
      if (log.nextDueAt == null) return Colors.transparent;
      final diff = log.nextDueAt!.difference(now).inDays;
      if (diff < 0) return theme.colorScheme.error;
      if (diff <= 30) return OhColors.amber400;
      return OhColors.sage600;
    }

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: theme.colorScheme.error,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Entry'),
            content: Text('Remove "${log.title}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            Icons.build,
            color: theme.colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        title: Text(log.title, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performed: ${fmt.format(log.performedAt)}'),
            if (log.cost != null) Text('Cost: ${log.cost!.toCurrency()}'),
          ],
        ),
        isThreeLine: log.cost != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (log.nextDueAt != null)
              Chip(
                label: Text(
                  'Due ${fmt.format(log.nextDueAt!)}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                backgroundColor: chipColor(),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../../domain/entities/maintenance_log.dart';
import '../controllers/maintenance_controller.dart';
import 'package:still_life/core/widgets/failure_feedback.dart';
import '../../../recently_deleted/presentation/undo_providers.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(maintenanceLogsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Log')),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
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
                    onDelete: () => _delete(ref, log),
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
                    onDelete: () => _delete(ref, log),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => loadFailure(
          e,
          st,
          title: "Couldn’t load maintenance",
          onRetry: () => ref.invalidate(maintenanceLogsProvider),
        ),
      ),
      ),
      bottomNavigationBar: OhUndoBar(
        controller: ref.watch(screenUndoControllerProvider('maintenance')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('addMaintenance'),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Deletes softly and offers Undo until the person leaves this screen.
  /// The menu choice is deliberate and does not ask; the swipe asks first
  /// (see [_MaintenanceTile]).
  Future<void> _delete(WidgetRef ref, MaintenanceLog log) async {
    final trash = ref.read(recentlyDeletedRepositoryProvider);
    final undo = ref.read(screenUndoControllerProvider('maintenance'));
    final ok = await ref.read(maintenanceControllerProvider.notifier).remove(log.id);
    if (!ok) return;
    undo.show(
      message: 'Deleted “${log.title}”',
      onUndo: () => trash.restoreMaintenanceLog(log.id),
    );
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
      // A swipe is easy to do by accident, so it asks first, naming the
      // act (fleet delete ruling). The delete is soft and offers Undo.
      confirmDismiss: (_) => showOhConfirm(
        context,
        title: 'Delete “${log.title}”?',
        message: 'You can undo this until you leave the Maintenance Log.',
        confirmLabel: 'Delete entry',
        destructive: true,
      ),
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
            if (log.costCents != null) Text('Cost: ${log.costCents!.centsToCurrency()}'),
          ],
        ),
        isThreeLine: log.costCents != null,
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
                PopupMenuItem(value: 'delete', child: Text('Delete entry')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../core/widgets/failure_feedback.dart';
import '../data/recently_deleted_repository.dart';
import 'undo_providers.dart';

final _deletedItemsProvider = StreamProvider.autoDispose<List<DeletedItem>>(
  (ref) => ref.watch(recentlyDeletedRepositoryProvider).watchDeletedItems(),
);

/// The lasting way back from deleting an item. Deletes are soft (the row
/// stays so devices you sync with learn of the delete), so every item
/// here can come back, with its photos. Nothing is purged on a timer.
class RecentlyDeletedScreen extends ConsumerWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedAsync = ref.watch(_deletedItemsProvider);
    final theme = Theme.of(context);
    final fmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Recently deleted')),
      body: OhPage(
        child: deletedAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Nothing deleted', style: theme.textTheme.titleLarge),
                    const SizedBox(height: OhSpacing.xs),
                    Text(
                      'Items you delete wait here, with their photos, '
                      'until you restore them.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: OhSpacing.sm),
                  child: Text(
                    'Deleted items stay here, with their photos, until you '
                    'restore them. They are kept so devices you sync with '
                    'learn about the delete too.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text('Deleted ${fmt.format(item.deletedAt)}'),
                    trailing: TextButton(
                      onPressed: () => _restore(context, ref, item),
                      child: const Text('Restore'),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => loadFailure(
            e,
            st,
            title: "Couldn’t load deleted items",
            onRetry: () => ref.invalidate(_deletedItemsProvider),
          ),
        ),
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    DeletedItem item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(recentlyDeletedRepositoryProvider).restoreItem(item.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Restored “${item.name}”')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureSentence("Couldn’t restore it", e))),
      );
    }
  }
}

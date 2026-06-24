import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/video_analysis_controller.dart';
import '../widgets/detected_item_card.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(videoAnalysisControllerProvider);
    final confirmed = ref.watch(confirmedObjectIdsProvider);
    final deleted = ref.watch(deletedObjectIdsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (session == null || session.detectedObjects.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Items')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: OhSpacing.md),
              Text('No items to review', style: theme.textTheme.titleMedium),
              const SizedBox(height: OhSpacing.lg),
              FilledButton.tonal(
                onPressed: () => context.go('/video/capture'),
                child: const Text('Scan a Room'),
              ),
            ],
          ),
        ),
      );
    }

    final objects = session.detectedObjects;
    // Separate into active and deleted lists for display.
    final activeObjects = objects
        .where((o) => !deleted.contains(o.id))
        .toList();
    final deletedObjects = objects
        .where((o) => deleted.contains(o.id))
        .toList();
    final confirmedCount = confirmed.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Items'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Badge(
              label: Text('${objects.length}'),
              child: const Icon(Icons.inventory_2_outlined),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${activeObjects.length} items detected',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (confirmedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: OhRadii.lg,
                    ),
                    child: Text(
                      '$confirmedCount confirmed',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                if (deleted.isNotEmpty) ...[
                  const SizedBox(width: OhSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: OhRadii.lg,
                    ),
                    child: Text(
                      '${deleted.length} removed',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Item list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Active items
                for (final obj in activeObjects)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DetectedItemCard(
                      object: obj,
                      isConfirmed: confirmed.contains(obj.id),
                      isDeleted: false,
                      onConfirm: () => ref
                          .read(videoAnalysisControllerProvider.notifier)
                          .confirmObject(obj.id),
                      onEdit: () {
                        ref.read(reviewEditObjectIdProvider.notifier).state =
                            obj.id;
                        context.push('/inventory/add');
                      },
                      onDelete: () {
                        final d = {...ref.read(deletedObjectIdsProvider)};
                        d.add(obj.id);
                        ref.read(deletedObjectIdsProvider.notifier).state = d;
                        // Also remove from confirmed.
                        final c = {...ref.read(confirmedObjectIdsProvider)};
                        c.remove(obj.id);
                        ref.read(confirmedObjectIdsProvider.notifier).state = c;
                      },
                    ),
                  ),

                // Deleted items section
                if (deletedObjects.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      'Removed',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final obj in deletedObjects)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DetectedItemCard(
                        object: obj,
                        isConfirmed: false,
                        isDeleted: true,
                        onDelete: () {
                          // Restore the item.
                          final d = {...ref.read(deletedObjectIdsProvider)};
                          d.remove(obj.id);
                          ref.read(deletedObjectIdsProvider.notifier).state = d;
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),

      // Bottom action bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref
                        .read(videoAnalysisControllerProvider.notifier)
                        .confirmAll();
                  },
                  child: const Text('Confirm All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: activeObjects.isEmpty
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Analysis complete — add items to inventory manually',
                              ),
                            ),
                          );
                          ref
                              .read(videoAnalysisControllerProvider.notifier)
                              .reset();
                          context.go('/inventory');
                        },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save to Inventory'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

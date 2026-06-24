import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/services/dashboard_aggregator.dart';

final _recentActivityProvider =
    FutureProvider<List<({String id, String name, DateTime modifiedAt})>>((
      ref,
    ) async {
      final db = ref.watch(databaseProvider);
      return DashboardAggregator(db).getRecentActivity();
    });

class RecentActivityWidget extends ConsumerWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(_recentActivityProvider);
    final theme = Theme.of(context);

    return activityAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: items.map((item) {
                  final diff = DateTime.now().difference(item.modifiedAt);
                  final label = diff.inDays >= 1
                      ? '${diff.inDays}d ago'
                      : diff.inHours >= 1
                      ? '${diff.inHours}h ago'
                      : '${diff.inMinutes}m ago';

                  return ListTile(
                    dense: true,
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    onTap: () => context.pushNamed(
                      'itemDetail',
                      pathParameters: {'itemId': item.id},
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

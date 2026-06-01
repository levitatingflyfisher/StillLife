import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../services/database/database.dart';

/// FutureProvider that fetches items with warranty expiring within 180 days.
final warrantyExpiringSoonProvider = FutureProvider<List<Item>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.itemDao.getWarrantyExpiringSoon(withinDays: 180);
});

class WarrantyExpiryWidget extends ConsumerWidget {
  const WarrantyExpiryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(warrantyExpiringSoonProvider);
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
                  Icons.verified_user_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: OhSpacing.sm),
                Text(
                  'Warranties Expiring Soon',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Text(
                    'No warranties expiring in the next 6 months',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  );
                }
                final displayed = items.take(5).toList();
                return Column(
                  children: displayed.map((item) {
                    final expiry = item.warrantyExpiration!;
                    final daysLeft = expiry.difference(DateTime.now()).inDays;
                    final chipColor = daysLeft <= 30
                        ? theme.colorScheme.error
                        : daysLeft <= 90
                        ? OhColors.amber400
                        : OhColors.sage600;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name, style: theme.textTheme.bodyMedium),
                      subtitle: Text(
                        'Expires ${fmt.format(expiry)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Chip(
                        label: Text(
                          daysLeft <= 0 ? 'Expired' : '$daysLeft days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: chipColor,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onTap: () => context.pushNamed(
                        'itemDetail',
                        pathParameters: {'itemId': item.id},
                      ),
                    );
                  }).toList(),
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

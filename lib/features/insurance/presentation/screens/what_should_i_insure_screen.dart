import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../services/insurance/insurance_gap_service.dart';
import '../../../inventory/domain/entities/item.dart';

final _insuranceGapServiceProvider = Provider<InsuranceGapService>(
  (ref) => InsuranceGapService(ref.watch(databaseProvider)),
);

final _uncoveredItemsProvider = FutureProvider.autoDispose<List<Item>>((
  ref,
) async {
  return ref.watch(_insuranceGapServiceProvider).topUncovered(limit: 20);
});

/// Read-only summary of the highest-value items in the inventory that have
/// no insurance coverage. A quick prompt to add a policy.
class WhatShouldIInsureScreen extends ConsumerWidget {
  const WhatShouldIInsureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(_uncoveredItemsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('What should I insure?')),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'All your high-value items are marked as insured. Nice.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final fmt = NumberFormat.simpleCurrency(name: 'USD');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(120),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This list reflects items flagged "Not insured". '
                        'Items covered by a blanket policy may need to be '
                        'manually marked as insured.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        item.currentValue == null
                            ? 'No value'
                            : fmt.format(item.currentValue),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.pushNamed(
                        'itemDetail',
                        pathParameters: {'itemId': item.id},
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

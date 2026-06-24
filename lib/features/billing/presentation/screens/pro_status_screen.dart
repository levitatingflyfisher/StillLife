import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../../core/providers/billing_providers.dart';
import '../../domain/account.dart';
import '../widgets/upgrade_cta.dart';
import '../widgets/usage_meter.dart';

/// Pro & Billing status screen.
///
/// Pattern:
///   - `accountProvider` is `null` → free tier, show [UpgradeCta].
///   - `accountProvider` has data → show status chip + [UsageMeter] +
///     rotate/delete actions.
class ProStatusScreen extends ConsumerWidget {
  const ProStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accountProvider);
    final svc = ref.watch(billingServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pro & Billing')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (acc) {
          if (acc == null) {
            return Padding(
              padding: OhSpacing.insetMd,
              child: UpgradeCta(checkoutUrl: svc.buildCheckoutUrl()),
            );
          }
          return ListView(
            padding: OhSpacing.insetMd,
            children: [
              _StatusChip(status: acc.status),
              const SizedBox(height: OhSpacing.lg),
              UsageMeter(account: acc),
              const SizedBox(height: OhSpacing.lg),
              OutlinedButton(
                onPressed: () async {
                  final r = await svc.rotateBearer();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        r.when(
                          success: (_) => 'New bearer issued',
                          failure: (f) => 'Failed: ${f.message}',
                        ),
                      ),
                    ),
                  );
                  // ignore: unawaited_futures
                  ref.read(accountProvider.notifier).refresh();
                },
                child: const Text('Rotate bearer'),
              ),
              TextButton(
                onPressed: () async {
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Pro account?'),
                          content: const Text(
                            'This cancels your subscription and erases our '
                            'record of you.',
                          ),
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
                      ) ??
                      false;
                  if (!confirmed) return;
                  final r = await svc.deleteAccount();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        r.when(
                          success: (_) => 'Account deleted',
                          failure: (f) => 'Failed: ${f.message}',
                        ),
                      ),
                    ),
                  );
                  // ignore: unawaited_futures
                  ref.read(accountProvider.notifier).refresh();
                },
                child: Text(
                  'Delete Pro account',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SubscriptionStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    switch (status) {
      case SubscriptionStatus.active:
        label = 'Pro — active';
        color = OhColors.sage600;
      case SubscriptionStatus.pastDue:
        label = 'Pro — past due';
        color = OhColors.amber400;
      case SubscriptionStatus.canceled:
        label = 'Pro — canceled';
        color = OhColors.slate500;
      case SubscriptionStatus.none:
        label = 'Free';
        color = OhColors.slate500;
    }
    return Chip(
      backgroundColor: color.withValues(alpha: 0.15),
      label: Text(label, style: TextStyle(color: color)),
    );
  }
}

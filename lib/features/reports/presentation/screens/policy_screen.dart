import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../../domain/entities/policy.dart';
import '../controllers/policy_controller.dart';

class PolicyScreen extends ConsumerWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policiesAsync = ref.watch(policiesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Insurance Policies')),
      body: policiesAsync.when(
        data: (policies) {
          if (policies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.policy_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No policies yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your insurance policy to track coverage gaps',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(120),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Policy'),
                    onPressed: () => context.pushNamed('addPolicy'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: policies.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final policy = policies[index];
              return _PolicyTile(
                policy: policy,
                onEdit: () => context.pushNamed(
                  'editPolicy',
                  pathParameters: {'policyId': policy.id},
                ),
                onDelete: () async {
                  final confirmed = await _confirmDelete(context, policy);
                  if (confirmed && context.mounted) {
                    await ref
                        .read(policyControllerProvider.notifier)
                        .remove(policy.id);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('addPolicy'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Policy policy) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Policy'),
            content: Text(
              'Remove ${policy.provider} policy? This cannot be undone.',
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
  }
}

class _PolicyTile extends StatelessWidget {
  final Policy policy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PolicyTile({
    required this.policy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d, yyyy');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: policy.isExpired
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.policy,
          color: policy.isExpired
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(policy.provider, style: theme.textTheme.titleMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (policy.policyNumber != null)
            Text(
              'Policy #${policy.policyNumber}',
              style: theme.textTheme.bodySmall,
            ),
          if (policy.coverageAmount != null)
            Text('Coverage: ${policy.coverageAmount!.toCurrency()}'),
          if (policy.expiryDate != null)
            Text(
              policy.isExpired
                  ? 'Expired ${fmt.format(policy.expiryDate!)}'
                  : 'Expires ${fmt.format(policy.expiryDate!)}',
              style: TextStyle(
                color: policy.isExpired
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface.withAlpha(160),
                fontSize: 12,
              ),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

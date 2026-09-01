import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../../domain/entities/policy.dart';
import '../controllers/policy_controller.dart';
import 'package:still_life/core/widgets/failure_feedback.dart';
import '../../../recently_deleted/presentation/undo_providers.dart';
import 'package:openhearth_design/openhearth_design.dart';

class PolicyScreen extends ConsumerWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policiesAsync = ref.watch(policiesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Insurance Policies')),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: policiesAsync.when(
          data: (policies) {
            if (policies.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.policy_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
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
                        color: theme.colorScheme.onSurfaceVariant,
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
                  // Deliberate (a menu choice), so no question: delete softly
                  // and offer Undo until the person leaves this screen.
                  onDelete: () async {
                    final trash = ref.read(recentlyDeletedRepositoryProvider);
                    final undo = ref.read(
                      screenUndoControllerProvider('policies'),
                    );
                    final ok = await ref
                        .read(policyControllerProvider.notifier)
                        .remove(policy.id);
                    if (!ok) return;
                    undo.show(
                      message: 'Deleted ${policy.provider} policy',
                      onUndo: () => trash.restorePolicy(policy.id),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => loadFailure(
            e,
            st,
            title: "Couldn’t load policies",
            onRetry: () => ref.invalidate(policiesProvider),
          ),
        ),
      ),
      bottomNavigationBar: OhUndoBar(
        controller: ref.watch(screenUndoControllerProvider('policies')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('addPolicy'),
        child: const Icon(Icons.add),
      ),
    );
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
          if (policy.coverageAmountCents != null)
            Text('Coverage: ${policy.coverageAmountCents!.centsToCurrency()}'),
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
          PopupMenuItem(value: 'delete', child: Text('Delete policy')),
        ],
      ),
    );
  }
}

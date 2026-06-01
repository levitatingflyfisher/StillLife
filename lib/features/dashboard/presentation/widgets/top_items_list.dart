import 'package:flutter/material.dart';

import '../../../../core/extensions/currency_extensions.dart';

class TopItem {
  final int rank;
  final String name;
  final double value;

  const TopItem({required this.rank, required this.name, required this.value});
}

class TopItemsList extends StatelessWidget {
  final List<TopItem> items;

  const TopItemsList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(120),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '${item.rank}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(item.name, overflow: TextOverflow.ellipsis),
          trailing: Text(
            item.value.toCurrency(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}

import 'dart:io';
import 'package:openhearth_design/openhearth_design.dart';

import 'package:flutter/material.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../../domain/entities/item.dart';

class ItemListTile extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? primaryPhotoPath;
  final bool isOnLoan;
  final double? quantity;
  final String? quantityUnit;
  final bool isLowStock;
  final VoidCallback? onDecrement;

  const ItemListTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.primaryPhotoPath,
    this.isOnLoan = false,
    this.quantity,
    this.quantityUnit,
    this.isLowStock = false,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: _buildLeading(theme),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (item.categoryName != null) item.categoryName!,
          if (item.roomName != null) item.roomName!,
        ].join(' - '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha(150),
        ),
      ),
      trailing: _buildTrailing(context),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = item.currentValue != null;
    final double? effectiveQuantity = quantity ?? item.quantity;
    if (!hasValue && !isOnLoan && effectiveQuantity == null) return null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasValue)
          Text(
            item.currentValue!.toCurrency(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        if (isOnLoan)
          Chip(
            label: const Text('On Loan'),
            labelStyle: theme.textTheme.labelSmall,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
        if (effectiveQuantity != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: OhRadii.lg,
                ),
                child: Text(
                  effectiveQuantity % 1 == 0
                      ? effectiveQuantity.toInt().toString()
                      : effectiveQuantity.toStringAsFixed(1),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isLowStock
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: onDecrement,
                tooltip: '−1',
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLeading(ThemeData theme) {
    if (primaryPhotoPath != null) {
      final file = File(primaryPhotoPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: OhRadii.md,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Image.file(file, fit: BoxFit.cover),
          ),
        );
      }
    }

    return CircleAvatar(
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.inventory_2_outlined,
        color: theme.colorScheme.onPrimaryContainer,
        size: 20,
      ),
    );
  }
}

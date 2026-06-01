import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../domain/entities/detected_object.dart';

/// Card displaying a single detected object with review action buttons.
class DetectedItemCard extends StatelessWidget {
  final DetectedObject object;
  final bool isConfirmed;
  final bool isDeleted;
  final VoidCallback? onConfirm;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DetectedItemCard({
    super.key,
    required this.object,
    this.isConfirmed = false,
    this.isDeleted = false,
    this.onConfirm,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedOpacity(
      duration: OhMotion.standard,
      opacity: isDeleted ? 0.45 : 1.0,
      child: Card(
        elevation: isConfirmed ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: OhRadii.lg,
          side: isConfirmed
              ? BorderSide(color: colorScheme.primary, width: 2)
              : isDeleted
              ? BorderSide(color: colorScheme.error.withAlpha(100))
              : BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: OhRadii.md,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.memory(
                    object.croppedImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row
                    Text(
                      object.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isDeleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: OhSpacing.xs),

                    // Category + brand/model
                    Row(
                      children: [
                        if (object.category != null) ...[
                          // Flexible + ellipsis so the chip shrinks instead of
                          // overflowing the row when the details column is
                          // squeezed at large accessibility text scales.
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: OhRadii.sm,
                              ),
                              child: Text(
                                object.category!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ),
                          const SizedBox(width: OhSpacing.sm),
                        ],
                        if (object.brand != null || object.model != null)
                          Expanded(
                            child: Text(
                              [
                                object.brand,
                                object.model,
                              ].whereType<String>().join(' '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),

                    if (object.description != null) ...[
                      const SizedBox(height: OhSpacing.xs),
                      Text(
                        object.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: OhSpacing.sm),

              // Right column: price + confidence + actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (object.estimatedPrice != null)
                    Text(
                      '\$${object.estimatedPrice!.toStringAsFixed(0)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '${(object.confidence * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OhSpacing.sm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onConfirm != null)
                        _ActionIcon(
                          icon: isConfirmed
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: isConfirmed
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          onTap: onConfirm!,
                          tooltip: 'Confirm',
                        ),
                      if (onEdit != null)
                        _ActionIcon(
                          icon: Icons.edit_outlined,
                          color: colorScheme.onSurfaceVariant,
                          onTap: onEdit!,
                          tooltip: 'Edit',
                        ),
                      if (onDelete != null)
                        _ActionIcon(
                          icon: isDeleted
                              ? Icons.restore_from_trash
                              : Icons.close_rounded,
                          color: isDeleted
                              ? colorScheme.tertiary
                              : colorScheme.error,
                          onTap: onDelete!,
                          tooltip: isDeleted ? 'Restore' : 'Delete',
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

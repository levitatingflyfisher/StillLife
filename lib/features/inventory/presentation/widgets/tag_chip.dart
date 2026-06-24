import 'package:flutter/material.dart';

import '../../domain/entities/tag.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  const TagChip({super.key, required this.tag, this.onTap, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final chipColor = tag.color != null ? Color(tag.color!) : null;

    if (onDeleted != null) {
      return InputChip(
        label: Text(tag.name),
        backgroundColor: chipColor?.withAlpha(40),
        side: chipColor != null
            ? BorderSide(color: chipColor.withAlpha(100))
            : null,
        onDeleted: onDeleted,
        onPressed: onTap,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }

    return ActionChip(
      label: Text(tag.name),
      backgroundColor: chipColor?.withAlpha(40),
      side: chipColor != null
          ? BorderSide(color: chipColor.withAlpha(100))
          : null,
      onPressed: onTap ?? () {},
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

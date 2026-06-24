import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tag.dart';
import '../controllers/tag_controller.dart';
import 'tag_chip.dart';

class TagSelectorWidget extends ConsumerStatefulWidget {
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onTagsChanged;

  const TagSelectorWidget({
    super.key,
    required this.selectedTagIds,
    required this.onTagsChanged,
  });

  @override
  ConsumerState<TagSelectorWidget> createState() => _TagSelectorWidgetState();
}

class _TagSelectorWidgetState extends ConsumerState<TagSelectorWidget> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedTagIds);
  }

  @override
  void didUpdateWidget(TagSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTagIds != widget.selectedTagIds) {
      _selectedIds = List.from(widget.selectedTagIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tags', style: theme.textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => _showTagPicker(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        tagsAsync.when(
          data: (allTags) {
            final selectedTags = allTags
                .where((t) => _selectedIds.contains(t.id))
                .toList();

            if (selectedTags.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'No tags assigned',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: selectedTags.map((tag) {
                return TagChip(
                  tag: tag,
                  onDeleted: () {
                    setState(() {
                      _selectedIds.remove(tag.id);
                    });
                    widget.onTagsChanged(_selectedIds);
                  },
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(
            height: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _showTagPicker(BuildContext context) async {
    final tagsAsync = ref.read(tagsProvider);
    final allTags = tagsAsync.value ?? [];

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) =>
          _TagPickerDialog(allTags: allTags, selectedIds: _selectedIds),
    );

    if (result != null) {
      setState(() {
        _selectedIds = result;
      });
      widget.onTagsChanged(result);
    }
  }
}

class _TagPickerDialog extends StatefulWidget {
  final List<Tag> allTags;
  final List<String> selectedIds;

  const _TagPickerDialog({required this.allTags, required this.selectedIds});

  @override
  State<_TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends State<_TagPickerDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.allTags.isEmpty
            ? const Center(
                child: Text(
                  'No tags created yet.\nGo to Settings > Tags to create tags.',
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.allTags.length,
                itemBuilder: (context, index) {
                  final tag = widget.allTags[index];
                  final isSelected = _selected.contains(tag.id);
                  final chipColor = tag.color != null
                      ? Color(tag.color!)
                      : null;

                  return CheckboxListTile(
                    value: isSelected,
                    title: Row(
                      children: [
                        if (chipColor != null) ...[
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: chipColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(tag.name),
                      ],
                    ),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(tag.id);
                        } else {
                          _selected.remove(tag.id);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

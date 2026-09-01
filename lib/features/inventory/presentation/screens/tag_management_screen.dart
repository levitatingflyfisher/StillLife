import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tag.dart';
import '../controllers/tag_controller.dart';
import 'package:still_life/core/widgets/failure_feedback.dart';
import '../../../recently_deleted/presentation/undo_providers.dart';
import 'package:openhearth_design/openhearth_design.dart';

class TagManagementScreen extends ConsumerWidget {
  const TagManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: tagsAsync.when(
          data: (tags) {
            if (tags.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tags yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose New tag to create your first one.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                final tagColor = tag.color != null ? Color(tag.color!) : null;

                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: tagColor ?? theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(tag.name),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete tag'),
                      ),
                    ],
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showTagDialog(context, ref, tag: tag);
                      } else if (action == 'delete') {
                        _delete(ref, tag);
                      }
                    },
                  ),
                  onTap: () => _showTagDialog(context, ref, tag: tag),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => loadFailure(
            e,
            st,
            title: "Couldn’t load tags",
            onRetry: () => ref.invalidate(tagsProvider),
          ),
        ),
      ),
      bottomNavigationBar: OhUndoBar(
        controller: ref.watch(screenUndoControllerProvider('tags')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTagDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New tag'),
      ),
    );
  }

  Future<void> _showTagDialog(
    BuildContext context,
    WidgetRef ref, {
    Tag? tag,
  }) async {
    final result = await showDialog<_TagDialogResult>(
      context: context,
      builder: (context) => _TagEditDialog(tag: tag),
    );

    if (result != null) {
      final controller = ref.read(tagControllerProvider.notifier);
      final now = DateTime.now();

      if (tag != null) {
        await controller.updateTag(
          tag.copyWith(
            name: result.name,
            color: () => result.color,
            modifiedAt: now,
          ),
        );
      } else {
        await controller.createTag(
          Tag(
            id: '',
            name: result.name,
            color: result.color,
            createdAt: now,
            modifiedAt: now,
          ),
        );
      }
    }
  }

  /// A menu choice is deliberate: delete softly, no question, and offer
  /// Undo until the person leaves this screen. The tag's links to items are
  /// removed by the delete, so they are captured first for the Undo.
  Future<void> _delete(WidgetRef ref, Tag tag) async {
    final trash = ref.read(recentlyDeletedRepositoryProvider);
    final undo = ref.read(screenUndoControllerProvider('tags'));
    final tagged = await trash.itemsTagged(tag.id);
    final ok = await ref.read(tagControllerProvider.notifier).deleteTag(tag.id);
    if (!ok) return;
    undo.show(
      message: 'Deleted tag “${tag.name}”. Your items are untouched.',
      onUndo: () => trash.restoreTag(tag.id, itemIds: tagged),
    );
  }
}

class _TagDialogResult {
  final String name;
  final int? color;

  _TagDialogResult({required this.name, this.color});
}

class _TagEditDialog extends StatefulWidget {
  final Tag? tag;

  const _TagEditDialog({this.tag});

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  final _nameController = TextEditingController();
  int? _selectedColor;

  static const _colors = [
    0xFFEF5350, // Red
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
    0xFF673AB7, // Deep Purple
    0xFF3F51B5, // Indigo
    0xFF2196F3, // Blue
    0xFF03A9F4, // Light Blue
    0xFF009688, // Teal
    0xFF4CAF50, // Green
    0xFF8BC34A, // Light Green
    0xFFFF9800, // Orange
    0xFF795548, // Brown
  ];

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _nameController.text = widget.tag!.name;
      _selectedColor = widget.tag!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tag != null ? 'Edit Tag' : 'New Tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tag name'),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          Text('Color', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedColor = isSelected ? null : color;
                }),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              _TagDialogResult(name: name, color: _selectedColor),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

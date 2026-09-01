import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/category.dart';
import '../controllers/category_controller.dart';
import 'package:still_life/core/widgets/failure_feedback.dart';
import '../../../recently_deleted/presentation/undo_providers.dart';
import 'package:openhearth_design/openhearth_design.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [OhBarActions(children: [
          OhBarOverflow<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'seed',
                child: Text('Reset to defaults'),
              ),
            ],
            onSelected: (action) {
              if (action == 'seed') {
                _confirmSeedDefaults(context, ref);
              }
            },
          ),
        ])],
      ),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No categories yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => ref
                          .read(categoryControllerProvider.notifier)
                          .seedDefaults(),
                      child: const Text('Load default categories'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      AppConstants.iconFromCodePoint(category.iconCodePoint),
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  title: Text(category.name),
                  subtitle: category.itemCount > 0
                      ? Text('${category.itemCount} items')
                      : null,
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete category'),
                      ),
                    ],
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showCategoryDialog(context, ref, category: category);
                      } else if (action == 'delete') {
                        _delete(ref, category);
                      }
                    },
                  ),
                  onTap: () =>
                      _showCategoryDialog(context, ref, category: category),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => loadFailure(
            e,
            st,
            title: "Couldn’t load categories",
            onRetry: () => ref.invalidate(categoriesProvider),
          ),
        ),
      ),
      bottomNavigationBar: OhUndoBar(
        controller: ref.watch(screenUndoControllerProvider('categories')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CategoryEditDialog(category: category),
    );

    if (result != null) {
      final controller = ref.read(categoryControllerProvider.notifier);
      final now = DateTime.now();

      if (category != null) {
        await controller.updateCategory(
          category.copyWith(name: result, modifiedAt: now),
        );
      } else {
        await controller.createCategory(
          Category(id: '', name: result, createdAt: now, modifiedAt: now),
        );
      }
    }
  }

  /// A menu choice is deliberate: delete softly, no question, and offer
  /// Undo until the person leaves this screen.
  Future<void> _delete(WidgetRef ref, Category category) async {
    final trash = ref.read(recentlyDeletedRepositoryProvider);
    final undo = ref.read(screenUndoControllerProvider('categories'));
    final ok = await ref
        .read(categoryControllerProvider.notifier)
        .deleteCategory(category.id);
    if (!ok) return;
    undo.show(
      message: 'Deleted category “${category.name}”',
      onUndo: () => trash.restoreCategory(category.id),
    );
  }

  Future<void> _confirmSeedDefaults(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Categories'),
        content: const Text(
          'This will add the default categories. Existing categories will not be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(categoryControllerProvider.notifier).seedDefaults();
    }
  }
}

class _CategoryEditDialog extends StatefulWidget {
  final Category? category;

  const _CategoryEditDialog({this.category});

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _controller.text = widget.category!.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category != null ? 'Edit Category' : 'New Category'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Category name'),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, name);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/profile_providers.dart';
import '../../domain/entities/profile.dart';
import '../profile_ui_constants.dart';

const _uuid = Uuid();

class ProfileManagementScreen extends ConsumerWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profiles')),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return Column(
              children: [
                const Expanded(
                  child: Center(child: Text('No profiles yet. Add one below.')),
                ),
                _AddProfileTile(onTap: () => _showCreateSheet(context, ref)),
              ],
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return _ProfileTile(
                      profile: profile,
                      onTap: () => _showEditSheet(context, ref, profile),
                      onDelete: () => _deleteProfile(context, ref, profile),
                      onSetDefault: () async {
                        final result = await ref
                            .read(profileRepositoryProvider)
                            .setDefault(profile.id);
                        result.when(
                          success: (_) {},
                          failure: (f) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to set default: ${f.message}',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              _AddProfileTile(onTap: () => _showCreateSheet(context, ref)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteProfile(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    if (profile.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the default profile')),
      );
      return;
    }
    final result = await ref
        .read(profileRepositoryProvider)
        .deleteProfile(profile.id);
    result.when(
      success: (_) {},
      failure: (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: ${f.message}')),
          );
        }
      },
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Profile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProfileEditSheet(profile: profile),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final blank = Profile(
      id: _uuid.v4(),
      name: '',
      colorHex: kDefaultProfileColor,
      avatarEmoji: kDefaultProfileEmoji,
      isDefault: false,
      createdAt: now,
      modifiedAt: now,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProfileEditSheet(profile: blank, isNew: true),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile tile
// ---------------------------------------------------------------------------

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.onTap,
    required this.onDelete,
    required this.onSetDefault,
  });

  final Profile profile;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Future<void> Function() onSetDefault;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: profileColor(profile.colorHex),
        child: Text(profile.avatarEmoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(profile.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              profile.isDefault ? Icons.star : Icons.star_border,
              color: profile.isDefault
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: profile.isDefault ? 'Default profile' : 'Set as default',
            onPressed: () async {
              await onSetDefault();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete profile',
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Add profile tile (shown at the bottom of the list)
// ---------------------------------------------------------------------------

class _AddProfileTile extends StatelessWidget {
  const _AddProfileTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add),
      title: const Text('Add profile'),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// ProfileEditSheet — bottom sheet for create / edit
// ---------------------------------------------------------------------------

class ProfileEditSheet extends ConsumerStatefulWidget {
  const ProfileEditSheet({
    super.key,
    required this.profile,
    this.isNew = false,
  });

  final Profile profile;
  final bool isNew;

  @override
  ConsumerState<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<ProfileEditSheet> {
  late final TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _selectedColor = widget.profile.colorHex;
    _selectedEmoji = widget.profile.avatarEmoji;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: 16 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isNew ? 'Add Profile' : 'Edit Profile',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: OhSpacing.md),

          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: OhSpacing.md),

          // Color swatches
          Text('Color', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: OhSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kProfileColors.map((hex) {
              final isSelected = hex == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: profileColor(hex),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: OhSpacing.md),

          // Emoji picker
          Text('Avatar', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: OhSpacing.sm),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: profileColor(_selectedColor),
                child: Text(
                  _selectedEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _showEmojiPicker,
                child: const Text('Change emoji'),
              ),
            ],
          ),
          const SizedBox(height: OhSpacing.lg),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(widget.isNew ? 'Add' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet<String>(
      context: context,
      builder: (_) => Padding(
        padding: OhSpacing.insetMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose emoji',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: kProfileEmojis.length,
              itemBuilder: (_, index) {
                final emoji = kProfileEmojis[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(emoji),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).then((picked) {
      if (picked != null && mounted) {
        setState(() => _selectedEmoji = picked);
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    final updated = widget.profile.copyWith(
      name: name,
      colorHex: _selectedColor,
      avatarEmoji: _selectedEmoji,
      modifiedAt: DateTime.now(),
    );

    final repo = ref.read(profileRepositoryProvider);
    final result = widget.isNew
        ? await repo.createProfile(updated)
        : await repo.updateProfile(updated);

    result.when(
      success: (_) {
        if (mounted) Navigator.of(context).pop();
      },
      failure: (f) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Save failed: ${f.message}')));
        }
      },
    );
  }
}

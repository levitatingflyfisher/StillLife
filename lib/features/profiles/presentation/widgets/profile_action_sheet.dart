import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/profile_providers.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../profile_ui_constants.dart';

class ProfileActionSheet extends ConsumerWidget {
  const ProfileActionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider).valueOrNull;
    final profiles = ref.watch(profilesProvider).valueOrNull ?? [];
    final query = ref.watch(inventoryQueryProvider);
    final isMyItemsOn = query.profileId != null;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "My items" toggle
          SwitchListTile(
            title: const Text('My items'),
            subtitle: const Text('Show only your items'),
            value: isMyItemsOn,
            onChanged: activeProfile == null
                ? null
                : (isOn) {
                    ref.read(inventoryQueryProvider.notifier).state = ref
                        .read(inventoryQueryProvider)
                        .copyWith(
                          profileId: isOn ? () => activeProfile.id : () => null,
                        );
                  },
          ),
          const Divider(height: 1),
          // Profile list
          ...profiles.map(
            (profile) => ListTile(
              leading: CircleAvatar(
                backgroundColor: profileColor(profile.colorHex),
                child: Text(profile.avatarEmoji),
              ),
              title: Text(profile.name),
              trailing: activeProfile?.id == profile.id
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                ref.read(activeProfileProvider.notifier).setActive(profile);
              },
            ),
          ),
          const Divider(height: 1),
          // Footer — manage profiles
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Manage profiles'),
            onTap: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.pushNamed('profiles');
            },
          ),
        ],
      ),
    );
  }
}

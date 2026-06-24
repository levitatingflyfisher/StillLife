import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/property.dart';
import '../../domain/entities/room.dart';
import '../controllers/location_controller.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    final propertiesAsync = ref.watch(propertiesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.room_preferences_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No rooms yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a property first, then create rooms.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                  const SizedBox(height: 24),
                  propertiesAsync.when(
                    data: (properties) {
                      if (properties.isEmpty) {
                        return FilledButton.icon(
                          onPressed: () => _showAddPropertyDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Property'),
                        );
                      }
                      return FilledButton.icon(
                        onPressed: () => _showAddRoomDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Room'),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _RoomTile(
                room: room,
                onTap: () => context.pushNamed(
                  'roomDetail',
                  pathParameters: {'roomId': room.id},
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final properties = ref.read(propertiesProvider).value ?? [];
          if (properties.isEmpty) {
            _showAddPropertyDialog(context, ref);
          } else {
            _showAddRoomDialog(context, ref);
          }
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddPropertyDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    // Capture notifiers before any await.
    final propertyNotifier = ref.read(propertyControllerProvider.notifier);
    final roomNotifier = ref.read(roomControllerProvider.notifier);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Property'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Property Name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (!context.mounted) {
      nameController.dispose();
      return;
    }

    if (result == true && nameController.text.trim().isNotEmpty) {
      final now = DateTime.now();
      await propertyNotifier.createProperty(
        Property(
          id: '',
          name: nameController.text.trim(),
          createdAt: now,
          modifiedAt: now,
        ),
      );
      if (!context.mounted) {
        nameController.dispose();
        return;
      }
      // Seed default rooms for the new property.
      final properties = ref.read(propertiesProvider).value ?? [];
      if (properties.isNotEmpty) {
        await roomNotifier.seedDefaults(properties.last.id);
      }
    }
    nameController.dispose();
  }

  Future<void> _showAddRoomDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final properties = ref.read(propertiesProvider).value ?? [];
    if (properties.isEmpty) {
      nameController.dispose();
      return;
    }
    // Capture notifier before the await.
    final roomNotifier = ref.read(roomControllerProvider.notifier);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Room'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Room Name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (!context.mounted) {
      nameController.dispose();
      return;
    }

    if (result == true && nameController.text.trim().isNotEmpty) {
      final now = DateTime.now();
      await roomNotifier.createRoom(
        Room(
          id: '',
          propertyId: properties.first.id,
          name: nameController.text.trim(),
          createdAt: now,
          modifiedAt: now,
        ),
      );
    }
    nameController.dispose();
  }
}

class _RoomTile extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;

  const _RoomTile({required this.room, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.room_outlined,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(room.name),
      subtitle: room.floor != null ? Text(room.floor!) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${room.itemCount} items', style: theme.textTheme.bodySmall),
        ],
      ),
      onTap: onTap,
    );
  }
}

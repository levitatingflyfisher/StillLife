import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/domain/repositories/item_repository.dart';
import '../../../inventory/presentation/controllers/quantity_controller.dart';
import '../../../inventory/presentation/helpers/item_add_helpers.dart';
import '../../../inventory/presentation/widgets/item_list_tile.dart';
import '../../../inventory/presentation/widgets/speed_dial_fab.dart';
import '../../../loans/presentation/controllers/loan_controller.dart';
import '../../domain/entities/storage_container.dart';
import '../controllers/location_controller.dart';

const _uuid = Uuid();

class RoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomDetailProvider(roomId));
    final containersAsync = ref.watch(containersInRoomProvider(roomId));
    final loanedIds = ref.watch(activeLoanedItemIdsProvider).valueOrNull ?? {};
    final lowStockIds =
        ref
            .watch(lowStockItemsProvider)
            .valueOrNull
            ?.map((i) => i.id)
            .toSet() ??
        {};
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: roomAsync.when(
          data: (room) => Text(room?.name ?? 'Room'),
          loading: () => const Text('Room'),
          error: (_, _) => const Text('Room'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Room'),
                  content: const Text(
                    'Are you sure? Items in this room will need to be reassigned.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref
                    .read(roomControllerProvider.notifier)
                    .deleteRoom(roomId);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: roomAsync.when(
        data: (room) {
          if (room == null) {
            return const Center(child: Text('Room not found'));
          }

          return CustomScrollView(
            slivers: [
              // Containers section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'Containers',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        onPressed: () => _addContainerDialog(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
              containersAsync.when(
                data: (containers) => containers.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            'No containers yet — add a shelf, box or drawer.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                    : SliverToBoxAdapter(
                        child: SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: containers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final c = containers[i];
                              return _ContainerChip(
                                container: c,
                                onTap: () => context.pushNamed(
                                  'containerDetail',
                                  pathParameters: {'containerId': c.id},
                                ),
                                onDelete: () => ref
                                    .read(containerControllerProvider.notifier)
                                    .delete(c.id),
                              );
                            },
                          ),
                        ),
                      ),
                loading: () =>
                    const SliverToBoxAdapter(child: LinearProgressIndicator()),
                error: (_, _) => const SliverToBoxAdapter(child: SizedBox()),
              ),
              const SliverToBoxAdapter(child: Divider()),

              // Items section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Items',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Items list
              StreamBuilder(
                stream: ref
                    .watch(itemRepositoryProvider)
                    .watchItems(ItemQuery(roomId: roomId)),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withAlpha(80),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No items in this room',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  150,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ItemListTile(
                        item: item,
                        isOnLoan: loanedIds.contains(item.id),
                        isLowStock: lowStockIds.contains(item.id),
                        quantity: item.quantity,
                        quantityUnit: item.quantityUnit,
                        onDecrement: item.isConsumable
                            ? () => ref
                                  .read(quantityControllerProvider)
                                  .decrement(item.id)
                            : null,
                        onTap: () => context.pushNamed(
                          'itemDetail',
                          pathParameters: {'itemId': item.id},
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: SpeedDialFab(
        onPhoto: () => onPhotoAddItem(context, ref, roomId: roomId),
        onVoice: () => onVoiceAddItem(context, ref, roomId: roomId),
        onManual: () =>
            context.pushNamed('addItem', queryParameters: {'roomId': roomId}),
      ),
    );
  }

  Future<void> _addContainerDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    String? selectedType;
    const types = ['Shelf', 'Box', 'Drawer', 'Cabinet', 'Closet', 'Other'];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Container'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Top shelf, Box A',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Type (optional)'),
                items: types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setSt(() => selectedType = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop();
                final now = DateTime.now();
                await ref
                    .read(containerControllerProvider.notifier)
                    .create(
                      StorageContainer(
                        id: _uuid.v4(),
                        roomId: roomId,
                        name: name,
                        type: selectedType,
                        createdAt: now,
                        modifiedAt: now,
                      ),
                    );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
  }
}

class _ContainerChip extends StatelessWidget {
  final StorageContainer container;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _ContainerChip({
    required this.container,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: Icon(_iconFor(container.type), size: 16),
      label: Text(container.name),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
      onPressed: onTap,
    );
  }

  IconData _iconFor(String? type) {
    return switch (type?.toLowerCase()) {
      'shelf' => Icons.shelves,
      'box' => Icons.inventory_2_outlined,
      'drawer' => Icons.density_medium,
      'cabinet' => Icons.door_sliding_outlined,
      'closet' => Icons.checkroom_outlined,
      _ => Icons.square_outlined,
    };
  }
}

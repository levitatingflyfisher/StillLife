import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:still_life/core/widgets/failure_feedback.dart';
import '../../../recently_deleted/presentation/undo_providers.dart';
import 'package:openhearth_design/openhearth_design.dart';

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
        actions: [OhBarActions(children: [
          OhBarAction(
            icon: Icons.delete_outline,
            label: 'Delete',
            // Deliberate (its own button), so no question: delete softly,
            // close, and let the shell offer an Undo with no timer.
            onPressed: () async {
              final name = roomAsync.valueOrNull?.name;
              final trash = ref.read(recentlyDeletedRepositoryProvider);
              final undo = ref.read(shellUndoControllerProvider);
              final ok = await ref
                  .read(roomControllerProvider.notifier)
                  .deleteRoom(roomId);
              if (!ok) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Couldn’t delete this room.")),
                  );
                }
                return;
              }
              undo.show(
                message: name == null ? 'Deleted the room' : 'Deleted room “$name”',
                onUndo: () => trash.restoreRoom(roomId),
              );
              if (context.mounted) context.pop();
            },
          ),
        ])],
      ),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: roomAsync.when(
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
                            'No containers yet—add a shelf, box or drawer.',
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
                              color: theme.colorScheme.onSurfaceVariant,
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
        error: (e, st) => loadFailure(
          e,
          st,
          title: "Couldn’t load this room",
          onRetry: () => ref.invalidate(roomDetailProvider(roomId)),
        ),
      ),
      ),
      floatingActionButton: SpeedDialFab(
        onPhoto: () => onPhotoAddItem(context, ref, roomId: roomId),
        onVoice: kIsWeb ? null : () => onVoiceAddItem(context, ref, roomId: roomId),
        onVideo: kIsWeb
            ? null
            : () => context.pushNamed(
                  'videoCapture',
                  queryParameters: {'roomId': roomId},
                ),
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

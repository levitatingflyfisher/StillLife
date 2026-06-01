import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/domain/repositories/item_repository.dart';
import '../../../inventory/presentation/controllers/quantity_controller.dart';
import '../../../inventory/presentation/helpers/item_add_helpers.dart';
import '../../../inventory/presentation/widgets/item_list_tile.dart';
import '../../../inventory/presentation/widgets/speed_dial_fab.dart';
import '../../../loans/presentation/controllers/loan_controller.dart';
import '../controllers/location_controller.dart';

class ContainerDetailScreen extends ConsumerWidget {
  final String containerId;

  const ContainerDetailScreen({super.key, required this.containerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerAsync = ref.watch(containerDetailProvider(containerId));
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
        title: containerAsync.when(
          data: (c) => Text(c?.name ?? 'Container'),
          loading: () => const Text('Container'),
          error: (_, _) => const Text('Container'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_outlined),
            tooltip: 'QR Label',
            onPressed: () => context.pushNamed(
              'containerLabel',
              pathParameters: {'containerId': containerId},
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: ref
            .watch(itemRepositoryProvider)
            .watchItems(ItemQuery(containerId: containerId)),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting &&
              items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return Center(
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
                    'No items in this container',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
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
      floatingActionButton: containerAsync.when(
        data: (container) => SpeedDialFab(
          onPhoto: () => onPhotoAddItem(
            context,
            ref,
            roomId: container?.roomId,
            containerId: containerId,
          ),
          onVoice: () => onVoiceAddItem(
            context,
            ref,
            roomId: container?.roomId,
            containerId: containerId,
          ),
          onManual: () => context.pushNamed(
            'addItem',
            queryParameters: {
              if (container?.roomId != null) 'roomId': container!.roomId,
              'containerId': containerId,
            },
          ),
        ),
        loading: () => null,
        error: (_, _) => null,
      ),
    );
  }
}

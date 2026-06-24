import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/repositories/item_repository.dart';
import '../controllers/inventory_controller.dart';
import '../helpers/item_add_helpers.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/item_list_tile.dart';
import '../widgets/speed_dial_fab.dart';
import '../controllers/quantity_controller.dart';
import '../../../loans/presentation/controllers/loan_controller.dart';
import '../../../profiles/presentation/widgets/profile_action_sheet.dart';
import '../../../search/presentation/controllers/search_controller.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  FilterResult _currentFilter = const FilterResult();

  // Bulk selection
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(String firstId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
      _selectedIds.add(firstId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final result = await showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterDialog(currentFilter: _currentFilter),
    );
    if (result != null) {
      setState(() => _currentFilter = result);
      final current = ref.read(inventoryQueryProvider);
      ref.read(inventoryQueryProvider.notifier).state = result.applyTo(current);
    }
  }

  Future<void> _bulkMoveToRoom() async {
    final rooms = await ref.read(roomRepositoryProvider).watchRooms().first;

    if (!mounted) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Move to Room'),
        children: rooms
            .map(
              (r) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, r.id),
                child: Text(r.name),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || !mounted) return;
    final count = _selectedIds.length;
    final result = await ref
        .read(itemRepositoryProvider)
        .moveItems(_selectedIds.toList(), selected);
    if (!mounted) return;
    result.when(
      success: (_) {
        _exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count == 1 ? 'Moved 1 item' : 'Moved $count items'),
          ),
        );
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Move failed: ${f.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  Future<void> _bulkDelete() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Items'),
        content: Text(
          'Delete $count item${count == 1 ? '' : 's'}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(itemRepositoryProvider)
        .deleteItems(_selectedIds.toList());
    if (!mounted) return;
    result.when(
      success: (_) {
        _exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count == 1 ? 'Deleted 1 item' : 'Deleted $count items',
            ),
          ),
        );
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${f.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryItemsProvider);
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
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outlined),
                  tooltip: 'Move to room',
                  onPressed: _bulkMoveToRoom,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete selected',
                  onPressed: _bulkDelete,
                ),
              ],
            )
          : AppBar(
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search items...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        final rawSearch = value.trim();
                        ItemQuery baseQuery;
                        if (rawSearch.isNotEmpty) {
                          final parsed = ref
                              .read(nlQueryParserProvider)
                              .parse(rawSearch);
                          baseQuery = ItemQuery(
                            searchText: parsed.residualText.isEmpty
                                ? null
                                : parsed.residualText,
                            roomId:
                                _currentFilter.roomId ?? parsed.query.roomId,
                            categoryId:
                                _currentFilter.categoryId ??
                                parsed.query.categoryId,
                            containerId: parsed.query.containerId,
                            minValue:
                                _currentFilter.minValue ??
                                parsed.query.minValue,
                            maxValue:
                                _currentFilter.maxValue ??
                                parsed.query.maxValue,
                            priceField: _currentFilter.priceField,
                            hasPhoto:
                                _currentFilter.hasPhoto ??
                                parsed.query.hasPhoto,
                            hasReceipt:
                                _currentFilter.hasReceipt ??
                                parsed.query.hasReceipt,
                            hasBarcode:
                                _currentFilter.hasBarcode ??
                                parsed.query.hasBarcode,
                            sortBy: parsed.query.sortBy,
                            ascending: parsed.query.ascending,
                          );
                        } else {
                          baseQuery = _currentFilter.applyTo(const ItemQuery());
                        }
                        ref.read(inventoryQueryProvider.notifier).state =
                            baseQuery;
                      },
                    )
                  : const Text('Inventory'),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        ref.read(inventoryQueryProvider.notifier).state =
                            const ItemQuery();
                      }
                    });
                  },
                ),
                Badge(
                  isLabelVisible: _currentFilter.isActive,
                  label: Text('${_currentFilter.activeFilterCount}'),
                  child: IconButton(
                    icon: Icon(
                      _currentFilter.isActive
                          ? Icons.filter_alt
                          : Icons.filter_alt_outlined,
                    ),
                    onPressed: () => _showFilterDialog(context),
                  ),
                ),
                // Profile chip
                Consumer(
                  builder: (context, ref, _) {
                    final activeProfile = ref
                        .watch(activeProfileProvider)
                        .valueOrNull;
                    if (activeProfile != null) {
                      return ActionChip(
                        avatar: Text(activeProfile.avatarEmoji),
                        label: Text(activeProfile.name),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          builder: (_) => const ProfileActionSheet(),
                        ),
                      );
                    }
                    return IconButton(
                      icon: const Icon(Icons.person_outline),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        builder: (_) => const ProfileActionSheet(),
                      ),
                    );
                  },
                ),
                PopupMenuButton<ItemSortField>(
                  icon: const Icon(Icons.sort),
                  onSelected: (field) {
                    final current = ref.read(inventoryQueryProvider);
                    ref.read(inventoryQueryProvider.notifier).state = ItemQuery(
                      searchText: current.searchText,
                      roomId: current.roomId,
                      categoryId: current.categoryId,
                      sortBy: field,
                      ascending: field == current.sortBy
                          ? !current.ascending
                          : true,
                    );
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: ItemSortField.name,
                      child: Text('Name'),
                    ),
                    const PopupMenuItem(
                      value: ItemSortField.currentValue,
                      child: Text('Value'),
                    ),
                    const PopupMenuItem(
                      value: ItemSortField.createdAt,
                      child: Text('Date Added'),
                    ),
                    const PopupMenuItem(
                      value: ItemSortField.replacementCost,
                      child: Text('Replacement Cost'),
                    ),
                  ],
                ),
              ],
            ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first item',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${items.length} items',
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      items
                          .fold(0.0, (sum, i) => sum + (i.currentValue ?? 0))
                          .toCurrency(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedIds.contains(item.id);

                    if (_selectionMode) {
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(item.id),
                        title: Text(item.name),
                        subtitle: Text(
                          item.currentValue?.toCurrency() ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                        secondary: isSelected
                            ? CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.check,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 18,
                                ),
                              )
                            : null,
                      );
                    }

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
                      onLongPress: () => _enterSelectionMode(item.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: _selectionMode
          ? null
          : SpeedDialFab(
              onPhoto: () => onPhotoAddItem(context, ref),
              onVoice: () => onVoiceAddItem(context, ref),
              onManual: () => context.pushNamed('addItem'),
            ),
    );
  }
}

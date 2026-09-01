import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:still_life/core/widgets/failure_feedback.dart';
import '../../../recently_deleted/presentation/undo_providers.dart';
import 'package:openhearth_design/openhearth_design.dart';
import '../../../settings/presentation/controllers/theme_controller.dart';

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
            content: Text(failureSentence("Couldn’t move the items", f.message)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  /// A deliberate delete (select, then Delete): it acts at once and offers
  /// an Undo with no timer, per the fleet delete ruling. The delete is soft,
  /// so the Undo is real; Recently deleted in Settings keeps the way back.
  Future<void> _bulkDelete() async {
    final ids = _selectedIds.toList();
    final count = ids.length;
    final trash = ref.read(recentlyDeletedRepositoryProvider);
    final undo = ref.read(shellUndoControllerProvider);
    final deletion = await trash.snapshot(ids);
    final result = await ref.read(itemRepositoryProvider).deleteItems(ids);
    if (!mounted) return;
    result.when(
      success: (_) {
        _exitSelectionMode();
        undo.show(
          message: count == 1 ? 'Deleted 1 item' : 'Deleted $count items',
          onUndo: () => trash.restoreItems(deletion),
        );
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failureSentence("Couldn’t delete the items", f.message),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  void _sortBy(ItemSortField field) {
    final current = ref.read(inventoryQueryProvider);
    ref.read(inventoryQueryProvider.notifier).state = ItemQuery(
      searchText: current.searchText,
      roomId: current.roomId,
      categoryId: current.categoryId,
      sortBy: field,
      ascending: field == current.sortBy ? !current.ascending : true,
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
              actions: [OhBarActions(children: [
                OhBarAction(
                  icon: Icons.drive_file_move_outlined,
                  label: 'Move',
                  onPressed: _bulkMoveToRoom,
                ),
                OhBarAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onPressed: _bulkDelete,
                ),
              ])],
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
                            minValueCents:
                                _currentFilter.minValueCents ??
                                parsed.query.minValueCents,
                            maxValueCents:
                                _currentFilter.maxValueCents ??
                                parsed.query.maxValueCents,
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
              actions: [OhBarActions(children: [
                OhBarAction(
                  icon: _isSearching ? Icons.close : Icons.search,
                  label: _isSearching ? 'Close' : 'Search',
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
                  child: OhBarAction(
                    icon: _currentFilter.isActive
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                    label: 'Filter',
                    onPressed: () => _showFilterDialog(context),
                  ),
                ),
                // Rarer commands go in a worded menu (fleet ruling): sort,
                // who is using the app, and the theme (still two taps).
                _InventoryMoreMenu(onSort: _sortBy),
              ])],
            ),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
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
                    'Choose Add item to start your catalogue. One room is '
                    'enough for a first pass.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
                // Wrap, not Row: at large text the count and the total
                // do not fit side by side on a narrow phone.
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 16,
                  children: [
                    Text(
                      '${items.length} items',
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      items
                          .fold(0, (int sum, i) => sum + (i.currentValueCents ?? 0))
                          .centsToCurrency(),
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
                          item.currentValueCents.centsToCurrencyOrEmpty(),
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
        error: (e, st) => loadFailure(
          e,
          st,
          title: "Couldn’t load your items",
          onRetry: () => ref.invalidate(inventoryItemsProvider),
        ),
      ),
      ),
      floatingActionButton: _selectionMode
          ? null
          : SpeedDialFab(
              onPhoto: () => onPhotoAddItem(context, ref),
              onVoice: kIsWeb ? null : () => onVoiceAddItem(context, ref),
              onVideo: kIsWeb
                  ? null
                  : () => context.pushNamed('videoCapture'),
              onManual: () => context.pushNamed('addItem'),
            ),
    );
  }
}

enum _More { sortName, sortValue, sortAdded, sortReplacement, profile, themeSystem, themeLight, themeDark }

/// Inventory's worded overflow: "More", then named choices.
class _InventoryMoreMenu extends ConsumerWidget {
  const _InventoryMoreMenu({required this.onSort});

  final ValueChanged<ItemSortField> onSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final theme = ref.watch(themePreferenceProvider);
    PopupMenuItem<_More> check(_More v, String label, bool on) =>
        CheckedPopupMenuItem<_More>(value: v, checked: on, child: Text(label));
    return OhBarOverflow<_More>(
      onSelected: (v) {
        switch (v) {
          case _More.sortName:
            onSort(ItemSortField.name);
          case _More.sortValue:
            onSort(ItemSortField.currentValueCents);
          case _More.sortAdded:
            onSort(ItemSortField.createdAt);
          case _More.sortReplacement:
            onSort(ItemSortField.replacementCostCents);
          case _More.profile:
            showModalBottomSheet<void>(
              context: context,
              builder: (_) => const ProfileActionSheet(),
            );
          case _More.themeSystem:
            ref.read(themePreferenceProvider.notifier).set(OhThemeModePreference.system);
          case _More.themeLight:
            ref.read(themePreferenceProvider.notifier).set(OhThemeModePreference.light);
          case _More.themeDark:
            ref.read(themePreferenceProvider.notifier).set(OhThemeModePreference.dark);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: _More.sortName, child: Text('Sort by name')),
        const PopupMenuItem(value: _More.sortValue, child: Text('Sort by value')),
        const PopupMenuItem(value: _More.sortAdded, child: Text('Sort by date added')),
        const PopupMenuItem(
          value: _More.sortReplacement,
          child: Text('Sort by replacement cost'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _More.profile,
          child: Text(
            profile == null
                ? 'Who is using the app'
                : 'Using as ${profile.avatarEmoji} ${profile.name}',
          ),
        ),
        const PopupMenuDivider(),
        check(_More.themeSystem, 'Theme: follow phone', theme == OhThemeModePreference.system),
        check(_More.themeLight, 'Theme: light', theme == OhThemeModePreference.light),
        check(_More.themeDark, 'Theme: dark', theme == OhThemeModePreference.dark),
      ],
    );
  }
}

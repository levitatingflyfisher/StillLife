import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../../inventory/presentation/widgets/item_list_tile.dart';
import '../../../locations/domain/entities/room.dart';
import '../../../locations/presentation/controllers/location_controller.dart';
import '../../data/services/saved_search_service.dart';
import '../../domain/services/nl_query_parser.dart';
import '../controllers/search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveSearch() async {
    final q = _query.trim();
    if (q.isEmpty) return;
    await ref
        .read(savedSearchServiceProvider)
        .save(SavedSearch(label: q, query: q));
    ref.invalidate(savedSearchesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final parser = ref.watch(nlQueryParserProvider);
    final savedAsync = ref.watch(savedSearchesProvider);
    final rooms = ref.watch(roomsProvider).valueOrNull ?? <Room>[];

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search all items…',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? _EmptyState(
              savedAsync: savedAsync,
              onChipTap: (q) {
                _ctrl.text = q;
                setState(() => _query = q.trim());
              },
            )
          : _ResultsView(
              query: _query,
              parser: parser,
              rooms: rooms,
              onSave: _saveSearch,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final AsyncValue<List<SavedSearch>> savedAsync;
  final ValueChanged<String> onChipTap;

  const _EmptyState({required this.savedAsync, required this.onChipTap});

  @override
  Widget build(BuildContext context) {
    final searches = savedAsync.valueOrNull ?? [];

    return Column(
      children: [
        if (searches.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: searches.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = searches[i];
                return FilterChip(
                  label: Text(s.label),
                  onSelected: (_) => onChipTap(s.query),
                );
              },
            ),
          ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
                ),
                const SizedBox(height: 12),
                Text(
                  'Type to search all items',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultsView extends ConsumerWidget {
  final String query;
  final NlQueryParser parser;
  final List<Room> rooms;
  final VoidCallback onSave;

  const _ResultsView({
    required this.query,
    required this.parser,
    required this.rooms,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsed = parser.parse(query);
    // Use a stable provider that re-subscribes when [query] changes — the
    // family argument becomes part of the provider key, so prop changes
    // automatically swap streams without manual StreamBuilder bookkeeping.
    final asyncItems = parsed.hasStructuredFilters
        ? ref.watch(searchItemsProvider(query)) // dummy — fall through below
        : ref.watch(
            searchItemsProvider(
              parsed.residualText.isNotEmpty ? parsed.residualText : query,
            ),
          );
    // Structured-filter path needs the full ItemQuery — fall back to a
    // direct stream there since the simple text family can't represent it.
    final useStructured = parsed.hasStructuredFilters;
    final structuredStream = useStructured
        ? ref.read(itemRepositoryProvider).watchItems(parsed.query)
        : null;

    return useStructured
        ? StreamBuilder<List<Item>>(
            stream: structuredStream,
            builder: (context, snapshot) {
              final items = snapshot.data ?? <Item>[];
              return _renderResults(
                context,
                items,
                isLoading:
                    snapshot.connectionState == ConnectionState.waiting &&
                    items.isEmpty,
              );
            },
          )
        : asyncItems.when(
            data: (items) => _renderResults(context, items, isLoading: false),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
  }

  Widget _renderResults(
    BuildContext context,
    List<Item> items, {
    required bool isLoading,
  }) {
    final parsed = parser.parse(query);
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No results for "$query"',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return Column(
      children: [
        if (parsed.isWhereIs) _WhereIsCard(items: items, rooms: rooms),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.bookmark_outline, size: 18),
              label: const Text('Save search'),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ItemListTile(
                item: item,
                onTap: () => context.pushNamed(
                  'itemDetail',
                  pathParameters: {'itemId': item.id},
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WhereIsCard extends StatelessWidget {
  final List<Item> items;
  final List<Room> rooms;

  const _WhereIsCard({required this.items, required this.rooms});

  @override
  Widget build(BuildContext context) {
    final roomMap = {for (final r in rooms) r.id: r.name};
    final displayItems = items.take(3).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...displayItems.map((item) {
              final roomName =
                  roomMap[item.roomId] ?? item.roomName ?? 'Unknown';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '  ›  ',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              roomName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../locations/presentation/controllers/location_controller.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../controllers/category_controller.dart';
import '../controllers/tag_controller.dart';

class FilterResult {
  final String? roomId;
  final String? categoryId;
  final List<String>? tagIds;
  final ItemCondition? condition;
  final double? minValue;
  final double? maxValue;
  final PriceField priceField;
  final bool? hasPhoto;
  final bool? hasReceipt;
  final bool? hasBarcode;
  final DateTime? addedAfter;
  final DateTime? addedBefore;

  const FilterResult({
    this.roomId,
    this.categoryId,
    this.tagIds,
    this.condition,
    this.minValue,
    this.maxValue,
    this.priceField = PriceField.currentValue,
    this.hasPhoto,
    this.hasReceipt,
    this.hasBarcode,
    this.addedAfter,
    this.addedBefore,
  });

  bool get isActive =>
      roomId != null ||
      categoryId != null ||
      (tagIds != null && tagIds!.isNotEmpty) ||
      condition != null ||
      minValue != null ||
      maxValue != null ||
      hasPhoto != null ||
      hasReceipt != null ||
      hasBarcode != null ||
      addedAfter != null ||
      addedBefore != null;

  int get activeFilterCount {
    var count = 0;
    if (roomId != null) count++;
    if (categoryId != null) count++;
    if (tagIds != null && tagIds!.isNotEmpty) count++;
    if (condition != null) count++;
    if (minValue != null || maxValue != null) count++;
    if (hasPhoto != null) count++;
    if (hasReceipt != null) count++;
    if (hasBarcode != null) count++;
    if (addedAfter != null || addedBefore != null) count++;
    return count;
  }

  ItemQuery applyTo(ItemQuery query) {
    return ItemQuery(
      searchText: query.searchText,
      roomId: roomId,
      categoryId: categoryId,
      tagIds: tagIds,
      condition: condition,
      minValue: minValue,
      maxValue: maxValue,
      priceField: priceField,
      addedAfter: addedAfter,
      addedBefore: addedBefore,
      hasPhoto: hasPhoto,
      hasReceipt: hasReceipt,
      hasBarcode: hasBarcode,
      sortBy: query.sortBy,
      ascending: query.ascending,
    );
  }
}

class FilterDialog extends ConsumerStatefulWidget {
  final FilterResult currentFilter;

  const FilterDialog({super.key, required this.currentFilter});

  @override
  ConsumerState<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<FilterDialog> {
  String? _roomId;
  String? _categoryId;
  List<String>? _tagIds;
  ItemCondition? _condition;
  PriceField _priceField = PriceField.currentValue;
  final _minValueController = TextEditingController();
  final _maxValueController = TextEditingController();
  bool? _hasPhoto;
  bool? _hasReceipt;
  bool? _hasBarcode;
  DateTime? _addedAfter;
  DateTime? _addedBefore;

  @override
  void initState() {
    super.initState();
    _roomId = widget.currentFilter.roomId;
    _categoryId = widget.currentFilter.categoryId;
    _tagIds = widget.currentFilter.tagIds != null
        ? List.from(widget.currentFilter.tagIds!)
        : null;
    _condition = widget.currentFilter.condition;
    _priceField = widget.currentFilter.priceField;
    _minValueController.text = widget.currentFilter.minValue?.toString() ?? '';
    _maxValueController.text = widget.currentFilter.maxValue?.toString() ?? '';
    _hasPhoto = widget.currentFilter.hasPhoto;
    _hasReceipt = widget.currentFilter.hasReceipt;
    _hasBarcode = widget.currentFilter.hasBarcode;
    _addedAfter = widget.currentFilter.addedAfter;
    _addedBefore = widget.currentFilter.addedBefore;
  }

  @override
  void dispose() {
    _minValueController.dispose();
    _maxValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomsAsync = ref.watch(roomsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final tagsAsync = ref.watch(tagsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter', style: theme.textTheme.titleLarge),
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: OhSpacing.insetMd,
                children: [
                  // Room filter
                  roomsAsync.when(
                    data: (rooms) => DropdownButtonFormField<String?>(
                      initialValue: _roomId,
                      decoration: const InputDecoration(labelText: 'Room'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All rooms'),
                        ),
                        ...rooms.map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _roomId = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: OhSpacing.md),

                  // Category filter
                  categoriesAsync.when(
                    data: (categories) => DropdownButtonFormField<String?>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All categories'),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: OhSpacing.md),

                  // Condition filter
                  DropdownButtonFormField<ItemCondition?>(
                    initialValue: _condition,
                    decoration: const InputDecoration(labelText: 'Condition'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Any condition'),
                      ),
                      ...ItemCondition.values.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _condition = v),
                  ),
                  const SizedBox(height: OhSpacing.md),

                  // Value range
                  Text('Value Range', style: theme.textTheme.titleSmall),
                  const SizedBox(height: OhSpacing.sm),
                  SegmentedButton<PriceField>(
                    segments: const [
                      ButtonSegment(
                        value: PriceField.purchasePrice,
                        label: Text('Purchase'),
                      ),
                      ButtonSegment(
                        value: PriceField.currentValue,
                        label: Text('Current'),
                      ),
                      ButtonSegment(
                        value: PriceField.replacementCost,
                        label: Text('Replace'),
                      ),
                    ],
                    selected: {_priceField},
                    onSelectionChanged: (s) =>
                        setState(() => _priceField = s.first),
                  ),
                  const SizedBox(height: OhSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minValueController,
                          decoration: const InputDecoration(labelText: 'Min'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxValueController,
                          decoration: const InputDecoration(labelText: 'Max'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OhSpacing.md),

                  // Tag filter
                  tagsAsync.when(
                    data: (tags) {
                      if (tags.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tags', style: theme.textTheme.titleSmall),
                          const SizedBox(height: OhSpacing.sm),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: tags.map((tag) {
                              final isSelected =
                                  _tagIds?.contains(tag.id) ?? false;
                              final chipColor = tag.color != null
                                  ? Color(tag.color!)
                                  : null;
                              return FilterChip(
                                selected: isSelected,
                                label: Text(tag.name),
                                backgroundColor: chipColor?.withAlpha(40),
                                selectedColor:
                                    chipColor?.withAlpha(100) ??
                                    theme.colorScheme.primaryContainer,
                                onSelected: (selected) {
                                  setState(() {
                                    _tagIds ??= [];
                                    if (selected) {
                                      _tagIds!.add(tag.id);
                                    } else {
                                      _tagIds!.remove(tag.id);
                                    }
                                    if (_tagIds!.isEmpty) _tagIds = null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: OhSpacing.md),
                  Text('Presence', style: theme.textTheme.titleSmall),
                  const SizedBox(height: OhSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('Has Photo'),
                        selected: _hasPhoto == true,
                        onSelected: (v) =>
                            setState(() => _hasPhoto = v ? true : null),
                      ),
                      FilterChip(
                        label: const Text('Has Receipt'),
                        selected: _hasReceipt == true,
                        onSelected: (v) =>
                            setState(() => _hasReceipt = v ? true : null),
                      ),
                      FilterChip(
                        label: const Text('Has Barcode'),
                        selected: _hasBarcode == true,
                        onSelected: (v) =>
                            setState(() => _hasBarcode = v ? true : null),
                      ),
                    ],
                  ),
                  const SizedBox(height: OhSpacing.md),
                  Text('Date Added', style: theme.textTheme.titleSmall),
                  const SizedBox(height: OhSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, size: 20),
                    title: Text(
                      _addedAfter == null
                          ? 'After: any'
                          : 'After: ${_addedAfter!.year}-${_addedAfter!.month.toString().padLeft(2, '0')}-${_addedAfter!.day.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _addedAfter ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _addedAfter = picked);
                    },
                    trailing: _addedAfter != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() => _addedAfter = null),
                          )
                        : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, size: 20),
                    title: Text(
                      _addedBefore == null
                          ? 'Before: any'
                          : 'Before: ${_addedBefore!.year}-${_addedBefore!.month.toString().padLeft(2, '0')}-${_addedBefore!.day.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _addedBefore ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _addedBefore = picked);
                    },
                    trailing: _addedBefore != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => _addedBefore = null),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: OhSpacing.insetMd,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _roomId = null;
      _categoryId = null;
      _tagIds = null;
      _condition = null;
      _priceField = PriceField.currentValue;
      _minValueController.clear();
      _maxValueController.clear();
      _hasPhoto = null;
      _hasReceipt = null;
      _hasBarcode = null;
      _addedAfter = null;
      _addedBefore = null;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      FilterResult(
        roomId: _roomId,
        categoryId: _categoryId,
        tagIds: _tagIds,
        condition: _condition,
        minValue: double.tryParse(_minValueController.text),
        maxValue: double.tryParse(_maxValueController.text),
        priceField: _priceField,
        hasPhoto: _hasPhoto,
        hasReceipt: _hasReceipt,
        hasBarcode: _hasBarcode,
        addedAfter: _addedAfter,
        addedBefore: _addedBefore,
      ),
    );
  }
}

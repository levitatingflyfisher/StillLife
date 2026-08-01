import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'photo_viewer_screen.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/money_input.dart';
import '../../../../core/providers/notification_providers.dart';
import '../../../../core/providers/product_lookup_providers.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../services/product_lookup/product_lookup_service.dart';
import '../../../locations/domain/entities/room.dart';
import '../../../locations/presentation/controllers/location_controller.dart';
import '../../domain/entities/category.dart' as domain;
import '../../domain/entities/item.dart';
import '../../domain/entities/item_suggestion.dart';
import '../../domain/entities/photo.dart';
import '../controllers/category_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/photo_controller.dart';
import '../controllers/tag_controller.dart';
import '../widgets/photo_gallery_widget.dart';
import '../widgets/tag_selector_widget.dart';
import 'package:collection/collection.dart';

const _uuid = Uuid();

/// Money fields accept digits plus both decimal separators, grouping
/// spaces, and currency symbols (pasted values) — parseMoneyInput decides
/// what they mean; the field validator rejects what it cannot parse.
final _moneyInputFilter = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9.,\s$€£¥₹¢]'),
);

class ItemEditScreen extends ConsumerStatefulWidget {
  final String? itemId;
  final String? initialRoomId;
  final String? initialContainerId;
  final String? initialBarcode;
  final ItemSuggestion? initialSuggestion;
  final bool showAiBanner;

  const ItemEditScreen({
    super.key,
    this.itemId,
    this.initialRoomId,
    this.initialContainerId,
    this.initialBarcode,
    this.initialSuggestion,
    this.showAiBanner = false,
  });

  bool get isEditing => itemId != null;

  @override
  ConsumerState<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends ConsumerState<ItemEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // The form is a lazy ListView: rows scrolled past the cache extent are
  // unmounted, so their validators deregister from the Form. The controller
  // + key let _save scroll the Valuation section back into view when an
  // off-screen money field fails the text-level check.
  final _scrollController = ScrollController();
  final _valuationKey = GlobalKey();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _replacementCostController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _storeUrlController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedRoomId;
  String? _selectedContainerId;
  ItemCondition? _selectedCondition;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiration;
  bool _isInsured = false;
  List<String> _selectedTagIds = [];
  bool _initialized = false;
  bool _prefilledFromWidget = false;
  bool _isLookingUp = false;
  String? _pendingCategoryName;
  bool _bannerDismissed = false;

  bool _trackQuantity = false;
  final _quantityController = TextEditingController();
  final _quantityUnitController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();

  String? _creatorProfileId;
  String? _ownerProfileId;
  DateTime? _createdAt;

  // ASIN has no form field — it arrives programmatically (e.g. marketplace
  // imports). Carried through an edit so saving never wipes it.
  String? _asin;

  // receiptId has no form field either — it arrives from receipt imports
  // (schema v14). Carried through an edit so saving never severs the
  // item's link to the receipt it came from.
  String? _receiptId;

  // Photo captured by the photo-add flow, waiting to be attached to the
  // item once it exists. Only used in add mode (editing has _PhotosSection).
  Uint8List? _pendingPhotoBytes;

  // Re-entrancy guard for _save() — a quick double-tap on the Save
  // button must not fire two parallel CRUD operations.
  bool _saving = false;

  /// Tapping the search icon: check cache first (free), then ask for consent
  /// before hitting the network.
  Future<void> _onLookupButtonPressed() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    // Always try the local cache — no network, no consent needed.
    setState(() => _isLookingUp = true);
    try {
      final service = ref.read(productLookupServiceProvider);
      final cached = await service.lookup(barcode, allowNetwork: false);
      if (!mounted) return;
      if (cached != null) {
        _applyProductInfo(cached);
        return;
      }

      // Cache miss — need network. Ask user if not already opted in.
      var enabled = ref.read(productLookupEnabledProvider).valueOrNull ?? false;
      if (!enabled) {
        final allow = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Online Product Lookup'),
            content: const Text(
              'Look up this barcode on Open Food Facts and UPCitemdb?\n\n'
              'Your IP address will be visible to those services. '
              'The result is cached locally so each barcode is only '
              'fetched once.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No thanks'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enable'),
              ),
            ],
          ),
        );
        if (allow != true || !mounted) return;
        await ref.read(productLookupEnabledProvider.notifier).setEnabled(true);
        enabled = true;
      }

      final info = await service.lookup(barcode, allowNetwork: true);
      if (!mounted) return;
      if (info != null) {
        _applyProductInfo(info);
      }
    } catch (_) {
      // Network errors are non-fatal
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  void _applyProductInfo(ProductInfo info) {
    if (_nameController.text.isEmpty) _nameController.text = info.name;
    if (_descriptionController.text.isEmpty && info.description != null) {
      _descriptionController.text = info.description!;
    }
    // ProductLookupCache has stored brand all along — apply it too.
    if (_brandController.text.isEmpty && info.brand != null) {
      _brandController.text = info.brand!;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Found: ${info.name}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _replacementCostController.dispose();
    _serialNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _barcodeController.dispose();
    _storeUrlController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _quantityUnitController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  /// Cents rendered as plain editable dollars text ("12.50"), no symbols.
  String _editText(int? cents) =>
      cents == null ? '' : (cents / 100).toStringAsFixed(2);

  void _initFromItem(Item item) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = item.name;
    _descriptionController.text = item.description;
    _purchasePriceController.text = _editText(item.purchasePriceCents);
    _currentValueController.text = _editText(item.currentValueCents);
    _replacementCostController.text = _editText(item.replacementCostCents);
    _serialNumberController.text = item.serialNumber ?? '';
    _brandController.text = item.brand ?? '';
    _modelController.text = item.model ?? '';
    _asin = item.asin;
    _receiptId = item.receiptId;
    _barcodeController.text = item.barcode ?? '';
    _storeUrlController.text = item.storeUrl ?? '';
    _notesController.text = item.notes ?? '';
    _selectedCategoryId = item.categoryId;
    _selectedRoomId = item.roomId;
    _selectedContainerId = item.containerId;
    _selectedCondition = item.condition;
    _purchaseDate = item.purchaseDate;
    _warrantyExpiration = item.warrantyExpiration;
    _isInsured = item.isInsured;
    _selectedTagIds = List.from(item.tagIds);
    _creatorProfileId = item.creatorProfileId;
    _ownerProfileId = item.ownerProfileId;
    _createdAt = item.createdAt;
    _trackQuantity = item.quantity != null;
    if (item.quantity != null) {
      _quantityController.text = item.quantity! % 1 == 0
          ? item.quantity!.toInt().toString()
          : item.quantity!.toStringAsFixed(1);
    }
    _quantityUnitController.text = item.quantityUnit ?? '';
    if (item.lowStockThreshold != null) {
      _lowStockThresholdController.text = item.lowStockThreshold! % 1 == 0
          ? item.lowStockThreshold!.toInt().toString()
          : item.lowStockThreshold!.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref
        .watch(categoryRepositoryProvider)
        .watchCategories();
    final roomsAsync = ref.watch(roomsProvider);
    final theme = Theme.of(context);

    // Apply pre-fill values from widget params (barcode scan / room CTA) and
    // from video-review edit (detected object data).
    if (!_prefilledFromWidget && !widget.isEditing) {
      _prefilledFromWidget = true;
      if (widget.initialRoomId != null) {
        _selectedRoomId = widget.initialRoomId;
      }
      if (widget.initialContainerId != null) {
        _selectedContainerId = widget.initialContainerId;
      }
      if (widget.initialBarcode != null) {
        _barcodeController.text = widget.initialBarcode!;
      }

      // Pre-fill from ItemSuggestion (photo / voice analysis result).
      if (widget.initialSuggestion != null) {
        final s = widget.initialSuggestion!;
        if (s.name != null) _nameController.text = s.name!;
        if (s.brand != null) _brandController.text = s.brand!;
        if (s.model != null) _modelController.text = s.model!;
        if (s.notes != null) _notesController.text = s.notes!;
        _pendingPhotoBytes = s.photoBytes;
        if (s.estimatedValue != null) {
          _currentValueController.text = s.estimatedValue!.toStringAsFixed(2);
        }
        _pendingCategoryName = s.categoryName;
      }
    }

    // If editing, load existing item
    if (widget.isEditing) {
      final itemAsync = ref.watch(itemDetailProvider(widget.itemId!));
      if (itemAsync.isLoading) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final item = itemAsync.value;
      if (item != null) _initFromItem(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Item' : 'Add Item'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.showAiBanner && !_bannerDismissed)
            MaterialBanner(
              content: const Text(
                'Set up AI analysis for automatic suggestions',
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pushNamed('llmSettings'),
                  child: const Text('Set Up'),
                ),
                TextButton(
                  onPressed: () => setState(() => _bannerDismissed = true),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: OhSpacing.insetMd,
                children: [
                  // Photos section (only when editing an existing item)
                  if (widget.isEditing) ...[
                    _PhotosSection(itemId: widget.itemId!),
                    const SizedBox(height: OhSpacing.md),
                  ],

                  // Photo captured by the photo-add flow: show the user it
                  // will attach to the item on save.
                  if (!widget.isEditing && _pendingPhotoBytes != null) ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _pendingPhotoBytes!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 72,
                              height: 72,
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Photo will be attached when you save.'),
                        ),
                      ],
                    ),
                    const SizedBox(height: OhSpacing.md),
                  ],

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: OhSpacing.md),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: OhSpacing.md),

                  // Category dropdown with inline create
                  StreamBuilder(
                    stream: categoriesAsync,
                    builder: (context, snapshot) {
                      final categories = snapshot.data ?? [];
                      // Match pending category name from suggestion once categories load.
                      if (_pendingCategoryName != null &&
                          categories.isNotEmpty) {
                        final match = categories.firstWhereOrNull(
                          (c) =>
                              c.name.toLowerCase() ==
                              _pendingCategoryName!.toLowerCase(),
                        );
                        if (match != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _selectedCategoryId = match.id;
                                _pendingCategoryName = null;
                              });
                            }
                          });
                        }
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              // Use `value` (not `initialValue`) so that external
                              // setState calls — e.g. after inline category creation
                              // — are reflected immediately.  Guard against the brief
                              // window where the stream hasn't emitted the new row yet.
                              // ignore: deprecated_member_use
                              value:
                                  categories.any(
                                    (c) => c.id == _selectedCategoryId,
                                  )
                                  ? _selectedCategoryId
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                              ),
                              validator: (v) =>
                                  v == null ? 'Category is required' : null,
                              items: categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCategoryId = v),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: OhIconButton.filledTonal(
                              icon: const Icon(Icons.add, size: 20),
                              tooltip: 'New category',
                              onPressed: () => _createCategoryInline(context),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: OhSpacing.md),

                  // Room dropdown with inline create
                  roomsAsync.when(
                    data: (rooms) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            // Same controlled-value pattern as the category dropdown.
                            // ignore: deprecated_member_use
                            value: rooms.any((r) => r.id == _selectedRoomId)
                                ? _selectedRoomId
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Room *',
                            ),
                            validator: (v) =>
                                v == null ? 'Room is required' : null,
                            items: rooms
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r.id,
                                    child: Text(r.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedRoomId = v),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OhIconButton.filledTonal(
                            icon: const Icon(Icons.add, size: 20),
                            tooltip: 'New room',
                            onPressed: () => _createRoomInline(context),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading rooms: $e'),
                  ),
                  const SizedBox(height: OhSpacing.md),

                  // Container (optional) — only shown when a room is selected
                  if (_selectedRoomId != null)
                    Builder(
                      builder: (context) {
                        // Watch the provider itself (.stream is deprecated);
                        // AsyncValue keeps the last data across rebuilds.
                        final containers = ref
                                .watch(
                                  containersInRoomProvider(_selectedRoomId!),
                                )
                                .value ??
                            [];
                        return DropdownButtonFormField<String?>(
                          // ignore: deprecated_member_use
                          value:
                              containers.any(
                                (c) => c.id == _selectedContainerId,
                              )
                              ? _selectedContainerId
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Container (optional)',
                            hintText: 'e.g. Top shelf, Moving box A',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('— none —'),
                            ),
                            ...containers.map(
                              (c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(
                                  c.type != null
                                      ? '${c.name} (${c.type})'
                                      : c.name,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedContainerId = v),
                        );
                      },
                    ),
                  const SizedBox(height: OhSpacing.lg),

                  // Valuation section
                  Text('Valuation',
                      key: _valuationKey, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Price',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          // Comma must be typeable: comma-decimal locales
                          // write 12,50. parseMoneyInput handles both
                          // separator conventions; the validator rejects
                          // what it cannot parse.
                          inputFormatters: [_moneyInputFilter],
                          validator: validateMoneyInput,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _currentValueController,
                          decoration: const InputDecoration(
                            labelText: 'Current Value',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [_moneyInputFilter],
                          validator: validateMoneyInput,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _replacementCostController,
                    decoration: const InputDecoration(
                      labelText: 'Replacement Cost',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_moneyInputFilter],
                    validator: validateMoneyInput,
                  ),
                  const SizedBox(height: 12),

                  // Purchase date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Purchase Date'),
                    subtitle: Text(
                      _purchaseDate != null
                          ? '${_purchaseDate!.month}/${_purchaseDate!.day}/${_purchaseDate!.year}'
                          : 'Not set',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(isPurchase: true),
                  ),
                  const SizedBox(height: OhSpacing.md),

                  // Condition
                  DropdownButtonFormField<ItemCondition>(
                    initialValue: _selectedCondition,
                    decoration: const InputDecoration(labelText: 'Condition'),
                    items: ItemCondition.values
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.label)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCondition = v),
                  ),
                  const SizedBox(height: OhSpacing.lg),

                  // Additional details
                  Text(
                    'Additional Details',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _serialNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Number',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: 'Barcode / UPC',
                      suffixIcon: _isLookingUp
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Camera scanning is native-only; on web the
                                // field stays fully typeable/pasteable.
                                if (!kIsWeb)
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    tooltip: 'Scan barcode',
                                    onPressed: () async {
                                      final scanned = await context
                                          .pushNamed<String?>(
                                            'barcodeScanner',
                                            queryParameters: {
                                              'returnMode': 'true',
                                            },
                                          );
                                      if (scanned != null && mounted) {
                                        setState(
                                          () =>
                                              _barcodeController.text = scanned,
                                        );
                                      }
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.search),
                                  tooltip: 'Look up product',
                                  onPressed: _onLookupButtonPressed,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _storeUrlController,
                    decoration: const InputDecoration(labelText: 'Store Link'),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),

                  // Warranty expiration
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Warranty Expiration'),
                    subtitle: Text(
                      _warrantyExpiration != null
                          ? '${_warrantyExpiration!.month}/${_warrantyExpiration!.day}/${_warrantyExpiration!.year}'
                          : 'Not set',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(isPurchase: false),
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Insured'),
                    value: _isInsured,
                    onChanged: (v) => setState(() => _isInsured = v),
                  ),
                  const SizedBox(height: OhSpacing.md),

                  // Tags
                  TagSelectorWidget(
                    selectedTagIds: _selectedTagIds,
                    onTagsChanged: (ids) =>
                        setState(() => _selectedTagIds = ids),
                  ),
                  const SizedBox(height: OhSpacing.md),

                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: OhSpacing.md),
                  SwitchListTile(
                    title: const Text('Track quantity'),
                    subtitle: const Text('Enable for pantry & supply items'),
                    value: _trackQuantity,
                    onChanged: (v) => setState(() {
                      _trackQuantity = v;
                      if (!v) {
                        _quantityController.clear();
                        _quantityUnitController.clear();
                        _lowStockThresholdController.clear();
                      }
                    }),
                  ),
                  if (_trackQuantity) ...[
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: OhSpacing.sm),
                    TextFormField(
                      controller: _quantityUnitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit (e.g. pcs, kg)',
                      ),
                    ),
                    const SizedBox(height: OhSpacing.sm),
                    TextFormField(
                      controller: _lowStockThresholdController,
                      decoration: const InputDecoration(
                        labelText: 'Low stock threshold',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createCategoryInline(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _QuickCreateDialog(
        title: 'New Category',
        labelText: 'Category name',
      ),
    );
    if (name == null || name.isEmpty) return;

    final now = DateTime.now();
    final id = _uuid.v4();
    final iconCode = AppConstants.categoryIcons[name];
    final category = domain.Category(
      id: id,
      name: name,
      iconCodePoint: iconCode,
      createdAt: now,
      modifiedAt: now,
    );
    final success = await ref
        .read(categoryControllerProvider.notifier)
        .createCategory(category);
    if (success) {
      setState(() => _selectedCategoryId = id);
    }
  }

  Future<void> _createRoomInline(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          const _QuickCreateDialog(title: 'New Room', labelText: 'Room name'),
    );
    if (name == null || name.isEmpty) return;

    // Use the first available property
    final properties = ref.read(propertiesProvider).value ?? [];
    if (properties.isEmpty) return;
    final propertyId = properties.first.id;

    final now = DateTime.now();
    final id = _uuid.v4();
    final room = Room(
      id: id,
      propertyId: propertyId,
      name: name,
      createdAt: now,
      modifiedAt: now,
    );
    final success = await ref
        .read(roomControllerProvider.notifier)
        .createRoom(room);
    if (success) {
      setState(() => _selectedRoomId = id);
    }
  }

  Future<void> _pickDate({required bool isPurchase}) async {
    final initial =
        (isPurchase ? _purchaseDate : _warrantyExpiration) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isPurchase) {
          _purchaseDate = picked;
        } else {
          _warrantyExpiration = picked;
        }
      });
    }
  }

  /// Validates the three money controllers' TEXT directly — the inline
  /// `validateMoneyInput` Form validators only run while their row is
  /// mounted, and the lazy ListView unmounts unfocused rows scrolled past
  /// the cache extent, silently deregistering them from the Form. Returns
  /// `"field label: error"` for the first bad field, or null.
  String? _moneyTextError() {
    final fields = {
      'Purchase Price': _purchasePriceController.text,
      'Current Value': _currentValueController.text,
      'Replacement Cost': _replacementCostController.text,
    };
    for (final field in fields.entries) {
      final error = validateMoneyInput(field.value);
      if (error != null) return '${field.key}: $error';
    }
    return null;
  }

  /// Brings the Valuation section back on screen so the user can see and
  /// fix the rejected money field, then re-runs the Form validators so the
  /// remounted field shows its inline error.
  void _revealValuationSection() {
    void ensureVisibleAndRevalidate() {
      final valuationContext = _valuationKey.currentContext;
      if (valuationContext != null) {
        Scrollable.ensureVisible(
          valuationContext,
          duration: const Duration(milliseconds: 250),
        );
      }
      _formKey.currentState?.validate();
    }

    if (_valuationKey.currentContext != null) {
      ensureVisibleAndRevalidate();
      return;
    }
    // Unmounted: jump toward the form top (the section sits within the
    // first viewport-and-a-bit) and retry once it has been built.
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ensureVisibleAndRevalidate();
      });
    }
  }

  Future<void> _save() async {
    // Double-tap guard — a queued tap fired during an in-flight save must
    // be a no-op, otherwise the same CRUD op runs twice.
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    // Mount-independent money check: validate() above cannot see money
    // rows the lazy ListView has unmounted, and a garbage price must never
    // become a silent null save (the inline validators stay for UX).
    final moneyError = _moneyTextError();
    if (moneyError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(moneyError)));
      _revealValuationSection();
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final quantity = _trackQuantity
          ? double.tryParse(_quantityController.text.trim())
          : null;
      final quantityUnit =
          _trackQuantity && _quantityUnitController.text.isNotEmpty
          ? _quantityUnitController.text.trim()
          : null;
      final lowStockThreshold = _trackQuantity
          ? double.tryParse(_lowStockThresholdController.text.trim())
          : null;
      final newId = widget.isEditing ? widget.itemId! : _uuid.v4();
      final item = Item(
        id: newId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        roomId: _selectedRoomId!,
        purchaseDate: _purchaseDate,
        // Money fields go through the locale-tolerant parser (the form
        // validator has already rejected anything it cannot parse, so a
        // typed price can no longer be silently dropped) straight to the
        // integer cents the database stores.
        purchasePriceCents:
            parseMoneyInputCents(_purchasePriceController.text),
        currentValueCents:
            parseMoneyInputCents(_currentValueController.text),
        replacementCostCents:
            parseMoneyInputCents(_replacementCostController.text),
        condition: _selectedCondition,
        serialNumber: _serialNumberController.text.isNotEmpty
            ? _serialNumberController.text.trim()
            : null,
        brand: _brandController.text.trim().isNotEmpty
            ? _brandController.text.trim()
            : null,
        model: _modelController.text.trim().isNotEmpty
            ? _modelController.text.trim()
            : null,
        asin: _asin,
        receiptId: _receiptId,
        warrantyExpiration: _warrantyExpiration,
        containerId: _selectedContainerId,
        barcode: _barcodeController.text.isNotEmpty
            ? _barcodeController.text.trim()
            : null,
        storeUrl: _storeUrlController.text.isNotEmpty
            ? _storeUrlController.text.trim()
            : null,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text.trim()
            : null,
        isInsured: _isInsured,
        quantity: quantity,
        quantityUnit: quantityUnit,
        lowStockThreshold: lowStockThreshold,
        creatorProfileId: _creatorProfileId,
        ownerProfileId: _ownerProfileId,
        createdAt: _createdAt ?? now,
        modifiedAt: now,
      );

      final controller = ref.read(itemControllerProvider.notifier);
      final bool success;
      if (widget.isEditing) {
        success = await controller.updateItem(item);
      } else {
        // Await the async-loaded active profile rather than reading
        // valueOrNull, which is null during the cold-launch window
        // before the AsyncNotifier resolves.
        final activeProfile = await ref.read(activeProfileProvider.future);
        final itemToSave = item.copyWith(
          creatorProfileId: () => activeProfile?.id,
        );
        success = await controller.createItem(itemToSave);

        // Attach the photo captured by the photo-add flow. The item is
        // saved either way — a failed photo write must not lose the item.
        if (success && _pendingPhotoBytes != null) {
          await ref
              .read(photoControllerProvider.notifier)
              .addPhoto(
                itemId: newId,
                bytes: _pendingPhotoBytes!,
                source: PhotoSource.camera,
              );
        }
      }

      if (success) {
        // Save tags
        final savedItemId = newId;
        if (_selectedTagIds.isNotEmpty || widget.isEditing) {
          await ref
              .read(tagControllerProvider.notifier)
              .setItemTags(savedItemId, _selectedTagIds);
        }

        // Schedule or cancel warranty reminder.
        final ns = ref.read(notificationServiceProvider);
        if (_warrantyExpiration != null) {
          ns
              .scheduleWarrantyReminder(
                itemId: savedItemId,
                itemName: item.name,
                expiryDate: _warrantyExpiration!,
              )
              .catchError((_) {});
        } else if (widget.isEditing) {
          ns.cancelWarrantyReminder(savedItemId).catchError((_) {});
        }
      }

      if (success && mounted) {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PhotosSection extends ConsumerWidget {
  final String itemId;

  const _PhotosSection({required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(itemPhotosProvider(itemId));

    return photosAsync.when(
      data: (photos) => PhotoGalleryWidget(
        photos: photos,
        onAddPhoto: () => _addPhoto(context, ref),
        onPhotoTap: (photo) {
          final index = photos.indexOf(photo);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PhotoViewerScreen(
                photos: photos,
                initialIndex: index < 0 ? 0 : index,
              ),
            ),
          );
        },
        onSetPrimary: (photo) => ref
            .read(photoControllerProvider.notifier)
            .setPrimary(itemId, photo.id),
        onDeletePhoto: (photo) => ref
            .read(photoControllerProvider.notifier)
            .deletePhoto(photo.id, photo.filePath),
      ),
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (picked != null) {
      // Bytes, not a path: works on every platform (web XFiles have no
      // usable filesystem path) and feeds the BLOB-backed photo store.
      final bytes = await picked.readAsBytes();
      await ref
          .read(photoControllerProvider.notifier)
          .addPhoto(
            itemId: itemId,
            bytes: bytes,
            source: source == ImageSource.camera
                ? PhotoSource.camera
                : PhotoSource.gallery,
          );
    }
  }
}

/// Simple dialog for quickly creating a category or room without
/// leaving the item form.
class _QuickCreateDialog extends StatefulWidget {
  final String title;
  final String labelText;

  const _QuickCreateDialog({required this.title, required this.labelText});

  @override
  State<_QuickCreateDialog> createState() => _QuickCreateDialogState();
}

class _QuickCreateDialogState extends State<_QuickCreateDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.labelText),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onSubmitted: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(_controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _submit(String value) {
    final name = value.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }
}

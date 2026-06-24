import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/photo.dart';
import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/label_id.dart';
import '../../../../features/profiles/domain/entities/profile.dart';
import '../controllers/inventory_controller.dart';
import 'photo_viewer_screen.dart';
import '../controllers/photo_controller.dart';
import '../controllers/tag_controller.dart';
import '../widgets/photo_gallery_widget.dart';
import '../widgets/price_history_chart.dart';
import '../widgets/tag_chip.dart';
import '../controllers/quantity_controller.dart';
import '../../../appraisal/presentation/widgets/appraisal_card.dart';
import '../../../loans/presentation/controllers/loan_controller.dart';
import '../../../loans/presentation/widgets/loan_status_card.dart';
import '../../../loans/presentation/widgets/add_loan_sheet.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(itemId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.pushNamed(
              'editItem',
              pathParameters: {'itemId': itemId},
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'label') {
                context.pushNamed(
                  'itemLabel',
                  pathParameters: {'itemId': itemId},
                );
              } else if (value == 'delete') {
                _confirmDelete(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'label', child: Text('Print QR Label')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: itemAsync.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Item not found'));
          }

          final photosAsync = ref.watch(itemPhotosProvider(itemId));
          final loans = ref.watch(itemLoansProvider(item.id)).valueOrNull ?? [];
          final activeLoan = loans.where((l) => l.isActive).firstOrNull;
          final pastLoans = loans.where((l) => !l.isActive).toList();

          return ListView(
            padding: OhSpacing.insetMd,
            children: [
              // Photo gallery
              photosAsync.when(
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
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: OhSpacing.md),

              // Item name
              Text(
                item.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                labelId(item.id),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(100),
                  letterSpacing: 0.4,
                ),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: OhSpacing.sm),
                Text(
                  item.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(180),
                  ),
                ),
              ],

              // Tags
              _buildTagSection(ref, itemId),

              // Owner chip
              _buildOwnerChip(context, ref, item),
              const SizedBox(height: OhSpacing.lg),

              // Value section
              Card(
                child: Padding(
                  padding: OhSpacing.insetMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Valuation', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Current Value',
                        value: item.currentValue?.toCurrency() ?? 'Not set',
                        isHighlighted: true,
                      ),
                      _DetailRow(
                        label: 'Replacement Cost',
                        value: item.replacementCost?.toCurrency() ?? 'Not set',
                      ),
                      _DetailRow(
                        label: 'Purchase Price',
                        value: item.purchasePrice?.toCurrency() ?? 'Not set',
                      ),
                      if (item.purchaseDate != null)
                        _DetailRow(
                          label: 'Purchase Date',
                          value: item.purchaseDate!.toShortDate(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Value history sparkline
              PriceHistoryChart(itemId: itemId),
              const SizedBox(height: 12),

              // Details section
              Card(
                child: Padding(
                  padding: OhSpacing.insetMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Details', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (item.condition != null)
                        _DetailRow(
                          label: 'Condition',
                          value: item.condition!.label,
                        ),
                      if (item.serialNumber != null)
                        _DetailRow(
                          label: 'Serial Number',
                          value: item.serialNumber!,
                        ),
                      if (item.barcode != null)
                        _DetailRow(label: 'Barcode', value: item.barcode!),
                      if (item.warrantyExpiration != null)
                        _DetailRow(
                          label: 'Warranty Expires',
                          value: item.warrantyExpiration!.toShortDate(),
                        ),
                      _DetailRow(
                        label: 'Insured',
                        value: item.isInsured ? 'Yes' : 'No',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Loan status card
              LoanStatusCard(
                loan: activeLoan,
                onLend: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      AddLoanSheet(itemId: item.id, itemName: item.name),
                ),
                onMarkReturned: () => ref
                    .read(loanControllerProvider.notifier)
                    .markReturned(activeLoan!.id),
                onEdit: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddLoanSheet(
                    itemId: item.id,
                    itemName: item.name,
                    editingLoan: activeLoan,
                  ),
                ),
              ),

              // Market value (appraiser) + item chat tile
              AppraisalCard(item: item),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('Ask about this item'),
                  subtitle: const Text(
                    'Chat with an AI assistant about this specific item.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(
                    'itemChat',
                    pathParameters: {'id': item.id},
                  ),
                ),
              ),

              // Quantity card (consumables only)
              if (item.isConsumable) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: OhSpacing.insetMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity', style: theme.textTheme.titleMedium),
                        const SizedBox(height: OhSpacing.sm),
                        Row(
                          children: [
                            Text(
                              item.quantity! % 1 == 0
                                  ? item.quantity!.toInt().toString()
                                  : item.quantity!.toStringAsFixed(1),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: item.isLowStock
                                    ? theme.colorScheme.error
                                    : null,
                              ),
                            ),
                            if (item.quantityUnit != null) ...[
                              const SizedBox(width: OhSpacing.xs),
                              Text(
                                item.quantityUnit!,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                            const Spacer(),
                            IconButton.filled(
                              icon: const Icon(Icons.remove),
                              onPressed: () => ref
                                  .read(quantityControllerProvider)
                                  .decrement(item.id),
                              tooltip: '−1',
                            ),
                          ],
                        ),
                        if (item.lowStockThreshold != null)
                          Text(
                            'Low stock below ${item.lowStockThreshold!.toInt()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              // Loan history
              if (pastLoans.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Loan History',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                ...pastLoans.map(
                  (l) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 16),
                    title: Text(l.borrowerName),
                    subtitle: Text('Returned ${l.returnedAt!.toShortDate()}'),
                  ),
                ),
              ],

              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: OhSpacing.insetMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notes', style: theme.textTheme.titleMedium),
                        const SizedBox(height: OhSpacing.sm),
                        Text(item.notes!),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Metadata
              Card(
                child: Padding(
                  padding: OhSpacing.insetMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        label: 'Added',
                        value: item.createdAt.toLongDate(),
                      ),
                      _DetailRow(
                        label: 'Last Modified',
                        value: item.modifiedAt.toLongDate(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildOwnerChip(BuildContext context, WidgetRef ref, Item item) {
    final profiles = ref.watch(profilesProvider).valueOrNull ?? [];
    final owner = profiles
        .where((p) => p.id == item.ownerProfileId)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ActionChip(
        label: Text(
          owner != null ? '${owner.avatarEmoji} ${owner.name}' : 'Unassigned',
        ),
        avatar: owner != null
            ? CircleAvatar(
                backgroundColor: _parseColor(owner.colorHex),
                child: Text(
                  owner.avatarEmoji,
                  style: const TextStyle(fontSize: 10),
                ),
              )
            : const CircleAvatar(child: Icon(Icons.person_outline, size: 14)),
        onPressed: () => _showOwnerAssignSheet(context, ref, item, profiles),
      ),
    );
  }

  Future<void> _showOwnerAssignSheet(
    BuildContext context,
    WidgetRef ref,
    Item item,
    List<Profile> profiles,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Assign Owner',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person_off_outlined),
                ),
                title: const Text('Unassigned'),
                trailing: item.ownerProfileId == null
                    ? const Icon(Icons.check)
                    : null,
                onTap: () async {
                  final result = await ref
                      .read(itemRepositoryProvider)
                      .updateItem(item.copyWith(ownerProfileId: () => null));
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                    result.when(
                      success: (_) {},
                      failure: (f) =>
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to update owner: ${f.message}',
                              ),
                            ),
                          ),
                    );
                  }
                },
              ),
              ...profiles.map((profile) {
                final isSelected = item.ownerProfileId == profile.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _parseColor(profile.colorHex),
                    child: Text(profile.avatarEmoji),
                  ),
                  title: Text(profile.name),
                  trailing: isSelected ? const Icon(Icons.check) : null,
                  onTap: () async {
                    final result = await ref
                        .read(itemRepositoryProvider)
                        .updateItem(
                          item.copyWith(ownerProfileId: () => profile.id),
                        );
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                      result.when(
                        success: (_) {},
                        failure: (f) =>
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update owner: ${f.message}',
                                ),
                              ),
                            ),
                      );
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Color _parseColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));

  Widget _buildTagSection(WidgetRef ref, String itemId) {
    final tagsAsync = ref.watch(itemTagsProvider(itemId));
    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: tags.map((tag) => TagChip(tag: tag)).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
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
      await ref
          .read(photoControllerProvider.notifier)
          .addPhoto(
            itemId: itemId,
            sourcePath: picked.path,
            source: source == ImageSource.camera
                ? PhotoSource.camera
                : PhotoSource.gallery,
          );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(itemControllerProvider.notifier)
          .deleteItem(itemId);
      if (success && context.mounted) {
        context.pop();
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          Text(
            value,
            style: isHighlighted
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

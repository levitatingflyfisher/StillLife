import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/profile_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/data/services/suggestion_batch_saver.dart';
import '../../../inventory/domain/entities/item_suggestion.dart';
import '../../../inventory/domain/entities/photo.dart';
import '../../../inventory/presentation/controllers/category_controller.dart';
import '../../../inventory/presentation/controllers/photo_controller.dart';
import '../../../locations/domain/entities/room.dart';
import '../../../locations/domain/entities/storage_container.dart';
import '../../../locations/presentation/controllers/location_controller.dart';
import '../../domain/entities/detected_object.dart';
import '../controllers/video_analysis_controller.dart';

/// Mutable per-item review state. Ephemeral — never persisted.
class _ReviewEntry {
  final DetectedObject object;
  final TextEditingController nameController;
  bool accepted;

  _ReviewEntry(this.object)
    : nameController = TextEditingController(text: object.displayName),
      accepted = true;
}

/// Reviews what the walkthrough found before anything is written: checkbox
/// per item (default accepted), inline name edit, batch room/container
/// pickers — the ShelfReviewScreen idiom. Saving goes through the shared
/// [SuggestionBatchSaver]; every accepted item gets its SOURCE FRAME
/// attached as a `videoFrame` photo.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late final List<_ReviewEntry> _entries;
  String? _roomId;
  String? _containerId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(videoAnalysisControllerProvider);
    _entries = (session?.detectedObjects ?? const [])
        .map(_ReviewEntry.new)
        .toList();
    _roomId = session?.roomId;
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.nameController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final saver = SuggestionBatchSaver(
        itemRepository: ref.read(itemRepositoryProvider),
        seeder: ref.read(importFallbackSeederProvider),
        addPhoto: ref.read(photoControllerProvider.notifier).addPhoto,
      );

      // Await the first emission — unlike shelf review this screen never
      // watches categoriesProvider, so valueOrNull may not be loaded yet.
      final categories = await ref.read(categoriesProvider.future);

      final result = await saver.saveAll(
        entries: [
          for (final entry in _entries)
            if (entry.accepted)
              SuggestionSaveEntry(
                name: entry.nameController.text,
                suggestion: ItemSuggestion(
                  brand: entry.object.brand,
                  model: entry.object.model,
                  categoryName: entry.object.category,
                  estimatedValue: entry.object.estimatedPrice,
                  notes: entry.object.description,
                  confidence: entry.object.confidence,
                ),
                // Each item carries ITS OWN source frame.
                photoBytes: entry.object.frameImage.isEmpty
                    ? null
                    : entry.object.frameImage,
                photoSource: PhotoSource.videoFrame,
              ),
        ],
        categories: categories,
        roomId: _roomId,
        containerId: _containerId,
        creatorProfileId: ref.read(activeProfileProvider).valueOrNull?.id,
      );

      if (mounted) {
        final saved = result.saved;
        final message = result.failed > 0
            ? 'Added $saved of ${saved + result.failed} items — '
                  '${result.failed} failed'
            : 'Added $saved item${saved == 1 ? '' : 's'}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        ref.read(videoAnalysisControllerProvider.notifier).reset();
        context.go('/inventory');
      }
    } catch (e) {
      // Keep the session and the screen — the user can retry; silence
      // here would discard the walkthrough's findings.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Items')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: OhSpacing.md),
              Text('No items to review', style: theme.textTheme.titleMedium),
              const SizedBox(height: OhSpacing.lg),
              FilledButton.tonal(
                onPressed: () => context.go('/video/capture'),
                child: const Text('Scan a Room'),
              ),
            ],
          ),
        ),
      );
    }

    final rooms = ref.watch(allRoomsProvider).valueOrNull ?? <Room>[];
    final containers = _roomId == null
        ? <StorageContainer>[]
        : ref.watch(containersInRoomProvider(_roomId!)).valueOrNull ??
              <StorageContainer>[];
    final acceptedCount = _entries.where((e) => e.accepted).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Review Items (${_entries.length})'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: OhSpacing.insetSm,
            child: Column(
              children: [
                if (rooms.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _roomId,
                    hint: const Text('Room for all items'),
                    items: [
                      for (final r in rooms)
                        DropdownMenuItem(value: r.id, child: Text(r.name)),
                    ],
                    onChanged: (v) => setState(() {
                      _roomId = v;
                      // Containers belong to a room; switching rooms
                      // invalidates the previous pick.
                      _containerId = null;
                    }),
                    decoration: const InputDecoration(
                      labelText: 'Room (applies to all)',
                      isDense: true,
                    ),
                  ),
                if (containers.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    initialValue: _containerId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No container'),
                      ),
                      for (final c in containers)
                        DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                    ],
                    onChanged: (v) => setState(() => _containerId = v),
                    decoration: const InputDecoration(
                      labelText: 'Container (applies to all)',
                      isDense: true,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: OhSpacing.insetSm,
              itemCount: _entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return _ReviewEntryTile(
                  entry: entry,
                  onChanged: () => setState(() {}),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          ref
                              .read(videoAnalysisControllerProvider.notifier)
                              .reset();
                          context.go('/video/capture');
                        },
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: (acceptedCount == 0 || _isSaving)
                      ? null
                      : _saveAll,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save to Inventory'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewEntryTile extends StatelessWidget {
  final _ReviewEntry entry;
  final VoidCallback onChanged;

  const _ReviewEntryTile({required this.entry, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final o = entry.object;
    final caption = [
      if (o.brand != null) o.brand!,
      if (o.model != null) o.model!,
      if (o.category != null) o.category!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: entry.accepted,
            onChanged: (v) {
              entry.accepted = v ?? false;
              onChanged();
            },
          ),
          ClipRRect(
            borderRadius: OhRadii.sm,
            child: SizedBox(
              width: 56,
              height: 56,
              child: o.frameImage.isEmpty
                  ? Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Image.memory(
                      o.frameImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: OhSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: entry.nameController,
                  enabled: entry.accepted,
                  style: theme.textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
                if (caption.isNotEmpty || o.confidence > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Row(
                      children: [
                        if (caption.isNotEmpty)
                          Flexible(
                            child: Text(
                              caption,
                              style: theme.textTheme.labelSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(width: OhSpacing.xs),
                        Text(
                          '${(o.confidence * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (o.estimatedPrice != null)
            Padding(
              padding: const EdgeInsets.only(left: OhSpacing.xs, top: 8),
              child: Text(
                '\$${o.estimatedPrice!.toStringAsFixed(2)}',
                style: theme.textTheme.labelMedium,
              ),
            ),
        ],
      ),
    );
  }
}

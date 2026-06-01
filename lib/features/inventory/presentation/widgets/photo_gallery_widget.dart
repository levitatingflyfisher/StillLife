import 'dart:io';
import 'package:openhearth_design/openhearth_design.dart';

import 'package:flutter/material.dart';

import '../../domain/entities/photo.dart';

class PhotoGalleryWidget extends StatelessWidget {
  final List<Photo> photos;
  final VoidCallback? onAddPhoto;
  final void Function(Photo photo)? onPhotoTap;
  final void Function(Photo photo)? onSetPrimary;
  final void Function(Photo photo)? onDeletePhoto;

  const PhotoGalleryWidget({
    super.key,
    required this.photos,
    this.onAddPhoto,
    this.onPhotoTap,
    this.onSetPrimary,
    this.onDeletePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (photos.isEmpty) {
      return _EmptyPhotoState(onAddPhoto: onAddPhoto);
    }

    final primary =
        photos.where((p) => p.isPrimary).firstOrNull ?? photos.first;
    final others = photos.where((p) => p.id != primary.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero image
        GestureDetector(
          onTap: () => onPhotoTap?.call(primary),
          child: ClipRRect(
            borderRadius: OhRadii.lg,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _PhotoImage(filePath: primary.filePath, fit: BoxFit.cover),
            ),
          ),
        ),

        if (others.isNotEmpty || onAddPhoto != null) ...[
          const SizedBox(height: OhSpacing.sm),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...others.map(
                  (photo) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onPhotoTap?.call(photo),
                      onLongPress: () => _showPhotoOptions(context, photo),
                      child: ClipRRect(
                        borderRadius: OhRadii.md,
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: _PhotoImage(
                            filePath: photo.filePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (onAddPhoto != null)
                  GestureDetector(
                    onTap: onAddPhoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: OhRadii.md,
                        border: Border.all(
                          color: theme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showPhotoOptions(BuildContext context, Photo photo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onSetPrimary != null)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Set as primary'),
                onTap: () {
                  Navigator.pop(context);
                  onSetPrimary?.call(photo);
                },
              ),
            if (onDeletePhoto != null)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDeletePhoto?.call(photo);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPhotoState extends StatelessWidget {
  final VoidCallback? onAddPhoto;

  const _EmptyPhotoState({this.onAddPhoto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onAddPhoto,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: OhRadii.lg,
          border: Border.all(
            color: theme.colorScheme.outline.withAlpha(80),
            width: 1,
          ),
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
              ),
              const SizedBox(height: OhSpacing.sm),
              Text(
                'Add photos',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  final String filePath;
  final BoxFit fit;

  const _PhotoImage({required this.filePath, required this.fit});

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Image.file(file, fit: fit);
  }
}

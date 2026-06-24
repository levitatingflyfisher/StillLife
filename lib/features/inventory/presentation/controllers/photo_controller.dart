import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../services/storage/photo_storage_service.dart';
import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';

/// Photo storage service provider.
final photoStorageServiceProvider = Provider<PhotoStorageService>((ref) {
  return PhotoStorageService();
});

/// Watch photos for an item.
final itemPhotosProvider = StreamProvider.family<List<Photo>, String>((
  ref,
  itemId,
) {
  return ref.watch(photoRepositoryProvider).watchItemPhotos(itemId);
});

/// Photo CRUD controller.
final photoControllerProvider =
    StateNotifierProvider<PhotoController, AsyncValue<void>>((ref) {
      return PhotoController(
        ref.watch(photoRepositoryProvider),
        ref.watch(photoStorageServiceProvider),
      );
    });

class PhotoController extends StateNotifier<AsyncValue<void>> {
  final PhotoRepository _repo;
  final PhotoStorageService _storage;

  PhotoController(this._repo, this._storage) : super(const AsyncData(null));

  /// Add a photo from a file path (camera or gallery).
  Future<bool> addPhoto({
    required String itemId,
    required String sourcePath,
    required PhotoSource source,
    bool setAsPrimary = false,
  }) async {
    state = const AsyncLoading();
    try {
      final savedPath = await _storage.savePhoto(
        itemId: itemId,
        sourcePath: sourcePath,
      );

      final now = DateTime.now();
      final photo = Photo(
        id: '',
        itemId: itemId,
        filePath: savedPath,
        isPrimary: setAsPrimary,
        source: source,
        capturedAt: now,
        createdAt: now,
        modifiedAt: now,
      );

      final result = await _repo.addPhoto(photo);
      return result.when(
        success: (_) {
          state = const AsyncData(null);
          return true;
        },
        failure: (f) {
          state = AsyncError(f.message, StackTrace.current);
          return false;
        },
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// Delete a photo (both file and DB record).
  Future<bool> deletePhoto(String photoId, String filePath) async {
    state = const AsyncLoading();
    try {
      await _storage.deletePhoto(filePath);
      final result = await _repo.deletePhoto(photoId);
      return result.when(
        success: (_) {
          state = const AsyncData(null);
          return true;
        },
        failure: (f) {
          state = AsyncError(f.message, StackTrace.current);
          return false;
        },
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// Set a photo as the primary photo for an item.
  Future<bool> setPrimary(String itemId, String photoId) async {
    state = const AsyncLoading();
    final result = await _repo.setPrimaryPhoto(itemId, photoId);
    return result.when(
      success: (_) {
        state = const AsyncData(null);
        return true;
      },
      failure: (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
    );
  }
}

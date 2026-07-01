import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:still_life/features/inventory/data/repositories/photo_repository_impl.dart';
import 'package:still_life/features/inventory/domain/entities/photo.dart';
import 'package:still_life/features/inventory/presentation/controllers/photo_controller.dart';
import 'package:still_life/services/database/database.dart' hide Photo;
import 'package:still_life/services/storage/photo_storage_service.dart';

import '../../../test_setup.dart';

/// After v12, a photo is captured as bytes (image_picker's XFile.readAsBytes
/// works on every platform) and stored as a BLOB — no filesystem anywhere in
/// the pipeline, so the identical code path runs on Android and the web.
void main() {
  ensureSqlite3();

  final jpegBytes = Uint8List.fromList(
    img.encodeJpg(img.Image(width: 32, height: 32)),
  );

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    final now = DateTime(2026);
    await db.into(db.properties).insert(PropertiesCompanion.insert(
        id: 'prop-1', name: 'Home', createdAt: now, modifiedAt: now));
    await db.into(db.rooms).insert(RoomsCompanion.insert(
        id: 'room-1',
        propertyId: 'prop-1',
        name: 'Study',
        createdAt: now,
        modifiedAt: now));
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        id: 'cat-1', name: 'Misc', createdAt: now, modifiedAt: now));
    await db.into(db.items).insert(ItemsCompanion.insert(
        id: 'item-1',
        name: 'Camera',
        categoryId: 'cat-1',
        roomId: 'room-1',
        createdAt: now,
        modifiedAt: now));
  });

  tearDown(() => db.close());

  group('PhotoRepositoryImpl', () {
    test('addPhoto persists bytes + thumbnail and maps them back', () async {
      final repo = PhotoRepositoryImpl(db);
      final now = DateTime(2026);

      final result = await repo.addPhoto(Photo(
        id: '',
        itemId: 'item-1',
        filePath: '',
        bytes: jpegBytes,
        thumbBytes: Uint8List.fromList([7, 7]),
        source: PhotoSource.gallery,
        capturedAt: now,
        createdAt: now,
        modifiedAt: now,
      ));

      final saved = result.when(success: (p) => p, failure: (f) => null);
      expect(saved, isNotNull);
      expect(saved!.bytes, jpegBytes);
      expect(saved.thumbBytes, Uint8List.fromList([7, 7]));

      final watched = await repo.watchItemPhotos('item-1').first;
      expect(watched.single.bytes, jpegBytes);
    });

    test('legacy rows (bytes null) still map cleanly', () async {
      await db.photoDao.insertPhoto(PhotosCompanion.insert(
        id: 'legacy',
        itemId: 'item-1',
        filePath: '/old/path.jpg',
        bytes: const Value(null),
        capturedAt: DateTime(2026),
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026),
      ));

      final repo = PhotoRepositoryImpl(db);
      final photos = await repo.watchItemPhotos('item-1').first;
      expect(photos.single.bytes, isNull);
      expect(photos.single.filePath, '/old/path.jpg');
    });
  });

  group('PhotoController', () {
    test('addPhoto stores bytes and derives a thumbnail', () async {
      final controller = PhotoController(
        PhotoRepositoryImpl(db),
        PhotoStorageService(),
      );

      final ok = await controller.addPhoto(
        itemId: 'item-1',
        bytes: jpegBytes,
        source: PhotoSource.camera,
      );
      expect(ok, isTrue);

      final rows = await db.photoDao.getItemPhotos('item-1');
      expect(rows.single.bytes, jpegBytes);
      expect(rows.single.thumbBytes, isNotNull,
          reason: 'controller must derive a thumbnail from the bytes');
      expect(rows.single.filePath, isEmpty,
          reason: 'byte-backed photos never touch the filesystem');
    });
  });
}

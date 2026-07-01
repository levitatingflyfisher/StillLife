import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:still_life/services/database/database.dart';

import '../../../test_setup.dart';

/// Schema v11 → v12 moves photo bytes into the database as BLOBs so photos
/// work identically on native and web (the web has no filesystem).
///
/// The migration must:
///  * add nullable `bytes` + `thumb_bytes` to photos and `photo_bytes` to
///    receipts,
///  * backfill each existing row by reading its legacy file from disk,
///  * keep the row (bytes = null) when the file is gone — never crash.
void main() {
  ensureSqlite3();

  /// A real decodable JPEG so the thumbnail step has something to chew on.
  final jpegBytes = Uint8List.fromList(
    img.encodeJpg(img.Image(width: 32, height: 32)),
  );

  /// Builds an in-memory database that looks like a real schema-v11 install:
  /// only the tables the v12 step touches, at their v11 shape, plus rows.
  raw.Database buildV11Database() {
    final db = raw.sqlite3.openInMemory();
    db.execute('CREATE TABLE items (id TEXT NOT NULL PRIMARY KEY)');
    db.execute('''
      CREATE TABLE photos (
        id TEXT NOT NULL PRIMARY KEY,
        item_id TEXT NOT NULL REFERENCES items (id),
        file_path TEXT NOT NULL,
        is_primary INTEGER NOT NULL DEFAULT 0,
        source TEXT NOT NULL DEFAULT 'camera',
        captured_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        modified_at INTEGER NOT NULL,
        node_id TEXT NOT NULL DEFAULT '',
        hlc TEXT NOT NULL DEFAULT '',
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE receipts (
        id TEXT NOT NULL PRIMARY KEY,
        item_id TEXT REFERENCES items (id),
        photo_path TEXT NOT NULL,
        store_name TEXT,
        purchase_date INTEGER,
        total_amount REAL,
        ocr_text TEXT,
        node_id TEXT NOT NULL DEFAULT '',
        hlc TEXT NOT NULL DEFAULT '',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    db.execute("INSERT INTO items (id) VALUES ('item-1')");
    db.execute(
      'INSERT INTO photos '
      '(id, item_id, file_path, captured_at, created_at, modified_at) VALUES '
      "('photo-kept', 'item-1', '/docs/photos/item-1/kept.jpg', 0, 0, 0), "
      "('photo-gone', 'item-1', '/docs/photos/item-1/gone.jpg', 0, 0, 0)",
    );
    db.execute(
      'INSERT INTO receipts (id, item_id, photo_path, created_at) VALUES '
      "('receipt-kept', 'item-1', '/docs/photos/receipts/r1.jpg', 0), "
      "('receipt-gone', 'item-1', '/docs/photos/receipts/r2.jpg', 0)",
    );
    db.execute('PRAGMA user_version = 11');
    return db;
  }

  group('v11 → v12 photo BLOB migration', () {
    late raw.Database rawDb;
    late AppDatabase db;
    late List<String> readPaths;

    setUp(() {
      rawDb = buildV11Database();
      readPaths = [];
      db = AppDatabase(
        NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
        migrationFileReader: (path) async {
          readPaths.add(path);
          if (path.endsWith('gone.jpg') || path.endsWith('r2.jpg')) {
            return null; // legacy file missing from disk
          }
          return jpegBytes;
        },
      );
    });

    tearDown(() async {
      await db.close();
      rawDb.dispose();
    });

    test('bumps user_version to the current schema and adds the blob columns',
        () async {
      await db.photoDao.getItemPhotos('item-1'); // triggers open + migration

      // Opening a v11 database migrates through v12 to the latest version.
      expect(rawDb.select('PRAGMA user_version').single.values.first,
          db.schemaVersion);
      final photoCols = rawDb
          .select('PRAGMA table_info(photos)')
          .map((r) => r['name'])
          .toList();
      expect(photoCols, containsAll(['bytes', 'thumb_bytes']));
      final receiptCols = rawDb
          .select('PRAGMA table_info(receipts)')
          .map((r) => r['name'])
          .toList();
      expect(receiptCols, contains('photo_bytes'));
    });

    test('backfills photo bytes and a thumbnail from the legacy file',
        () async {
      final photos = await db.photoDao.getItemPhotos('item-1');

      final kept = photos.singleWhere((p) => p.id == 'photo-kept');
      expect(kept.bytes, jpegBytes);
      expect(kept.thumbBytes, isNotNull,
          reason: 'a decodable image must gain a thumbnail');
      expect(readPaths, contains('/docs/photos/item-1/kept.jpg'));
    });

    test('keeps the row with null bytes when the legacy file is missing',
        () async {
      final photos = await db.photoDao.getItemPhotos('item-1');

      final gone = photos.singleWhere((p) => p.id == 'photo-gone');
      expect(gone.bytes, isNull);
      expect(gone.thumbBytes, isNull);
      expect(photos, hasLength(2), reason: 'missing file must not drop rows');
    });

    test('backfills receipt photo bytes, tolerating missing files', () async {
      await db.photoDao.getItemPhotos('item-1'); // open + migrate

      final rows = rawDb.select(
        'SELECT id, photo_bytes FROM receipts ORDER BY id',
      );
      expect(rows.first['id'], 'receipt-gone');
      expect(rows.first['photo_bytes'], isNull);
      expect(rows.last['id'], 'receipt-kept');
      expect(rows.last['photo_bytes'], jpegBytes);
    });
  });

  group('fresh v12 database', () {
    test('photo insert with bytes roundtrips', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
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
          name: 'Test item',
          categoryId: 'cat-1',
          roomId: 'room-1',
          createdAt: now,
          modifiedAt: now));
      await db.photoDao.insertPhoto(
        PhotosCompanion.insert(
          id: 'p1',
          itemId: 'item-1',
          filePath: '',
          bytes: Value(Uint8List.fromList([1, 2, 3])),
          thumbBytes: Value(Uint8List.fromList([9])),
          capturedAt: now,
          createdAt: now,
          modifiedAt: now,
        ),
      );

      final row = await db.photoDao.getPhotoById('p1');
      expect(row!.bytes, Uint8List.fromList([1, 2, 3]));
      expect(row.thumbBytes, Uint8List.fromList([9]));
    });
  });
}

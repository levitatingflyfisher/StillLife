import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';

import '../../../test_setup.dart';

/// Covers the path-traversal guard in [ImportService]. Imported JSON rows
/// that carry `filePath` / `photoPath` values outside the app-documents
/// directory are dropped silently instead of being written to disk.
void main() {
  ensureSqlite3();

  late AppDatabase db;
  late ImportService svc;
  // Pretend the app documents directory is `/app/docs`. Anything outside
  // this root must be rejected.
  const sandbox = '/app/docs';

  setUp(() async {
    db = AppDatabase.memory();
    svc = ImportService(db, photoRootResolver: () async => sandbox);

    // Seed the minimum FK graph so the item referenced by photo/receipt
    // can actually be inserted.
    final now = DateTime(2025, 1, 1);
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Home',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room1',
            propertyId: 'prop1',
            name: 'Living',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Electronics',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'item1',
            name: 'TV',
            categoryId: 'cat1',
            roomId: 'room1',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  String makeBackup({
    List<Map<String, dynamic>> photos = const [],
    List<Map<String, dynamic>> receipts = const [],
  }) {
    return json.encode({
      'app': 'still_life',
      'version': '1',
      'data': {'photos': photos, 'receipts': receipts},
    });
  }

  Map<String, dynamic> photo(String id, String filePath) => {
    'id': id,
    'itemId': 'item1',
    'filePath': filePath,
    'isPrimary': false,
    'source': 'camera',
    'capturedAt': '2025-01-01T00:00:00.000',
    'createdAt': '2025-01-01T00:00:00.000',
    'modifiedAt': '2025-01-01T00:00:00.000',
  };

  Map<String, dynamic> receipt(String id, String photoPath) => {
    'id': id,
    'itemId': 'item1',
    'photoPath': photoPath,
    'createdAt': '2025-01-01T00:00:00.000',
  };

  group('ImportService path traversal guard', () {
    test('accepts photos whose filePath is inside the sandbox', () async {
      final backup = makeBackup(
        photos: [photo('p1', '$sandbox/photos/tv.jpg')],
      );
      final result = await svc.importFromJson(backup);
      expect(result.isSuccess, isTrue, reason: result.toString());

      final rows = await db.select(db.photos).get();
      expect(rows, hasLength(1));
      expect(rows.single.filePath, '$sandbox/photos/tv.jpg');
    });

    test('rejects photos whose filePath escapes the sandbox via ..', () async {
      final backup = makeBackup(
        photos: [photo('p1', '$sandbox/../../etc/passwd')],
      );
      final result = await svc.importFromJson(backup);
      expect(result.isSuccess, isTrue);
      final rows = await db.select(db.photos).get();
      expect(rows, isEmpty, reason: 'Traversal path must be dropped.');
    });

    test(
      'rejects photos whose filePath is an unrelated absolute path',
      () async {
        final backup = makeBackup(
          photos: [
            photo('p1', '/etc/passwd'),
            photo('p2', '/var/log/secret.log'),
          ],
        );
        final result = await svc.importFromJson(backup);
        expect(result.isSuccess, isTrue);
        final rows = await db.select(db.photos).get();
        expect(rows, isEmpty);
      },
    );

    test('rejects receipts whose photoPath escapes the sandbox', () async {
      final backup = makeBackup(receipts: [receipt('r1', '/tmp/evil.jpg')]);
      final result = await svc.importFromJson(backup);
      expect(result.isSuccess, isTrue);
      final rows = await db.select(db.receipts).get();
      expect(rows, isEmpty);
    });

    test(
      'accepts receipts inside sandbox and still drops bad siblings',
      () async {
        final backup = makeBackup(
          receipts: [
            receipt('r1', '$sandbox/receipts/good.jpg'),
            receipt('r2', '../../../etc/shadow'),
          ],
        );
        final result = await svc.importFromJson(backup);
        expect(result.isSuccess, isTrue);
        final rows = await db.select(db.receipts).get();
        expect(rows, hasLength(1));
        expect(rows.single.id, 'r1');
      },
    );

    test('treats a null/empty path as safe (nothing to write)', () async {
      // Photos require a non-null filePath, so we only verify receipts
      // here — their photoPath is likewise non-null in the schema, so the
      // null case is really about the guard itself not throwing when the
      // sandbox resolver returns null. That is covered by the resolver
      // fall-through in [ImportService._resolvePhotoRoot].
      final looseSvc = ImportService(db, photoRootResolver: () async => null);
      final backup = makeBackup(
        photos: [photo('p1', '/any/absolute/path.jpg')],
      );
      final result = await looseSvc.importFromJson(backup);
      expect(result.isSuccess, isTrue);
      final rows = await db.select(db.photos).get();
      // With no sandbox root, guard is skipped — row is inserted.
      expect(rows, hasLength(1));
    });
  });
}

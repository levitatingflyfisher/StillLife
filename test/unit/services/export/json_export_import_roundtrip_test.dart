import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';

import '../../../test_setup.dart';

/// Tests for the JSON export/import round-trip — specifically focused on
/// preserving `isDeleted` soft-delete tombstones (so CRDT sync doesn't
/// resurrect them) and tolerating JSON `int`/`double` ambiguity on
/// numeric fields.
void main() {
  ensureSqlite3();

  late AppDatabase db;
  late JsonExportService exporter;
  late ImportService importer;

  setUp(() async {
    db = AppDatabase.memory();
    exporter = JsonExportService(db);
    importer = ImportService(db);

    // Seed minimal dependencies so items can round-trip.
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Home',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room1',
            propertyId: 'prop1',
            name: 'Kitchen',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Consumables',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
  });

  tearDown(() => db.close());

  test('export is a self-consistent snapshot (no orphan photo/receipt rows)',
      () async {
    // The export reads ~16 tables; it must present a single point-in-time view
    // so a photo/receipt never references an item id absent from the same file
    // (W4 F13). This guards the read-transaction wrapper: it exercises the
    // export while a concurrent LAN-sync-style import commits new item+photo
    // rows, and asserts the emitted snapshot is internally consistent.
    await db.into(db.items).insert(ItemsCompanion.insert(
        id: 'iA', name: 'A', categoryId: 'cat1', roomId: 'room1',
        createdAt: DateTime(2025), modifiedAt: DateTime(2025)));
    await db.into(db.photos).insert(PhotosCompanion.insert(
        id: 'phA', itemId: 'iA', filePath: '',
        capturedAt: DateTime(2025), createdAt: DateTime(2025),
        modifiedAt: DateTime(2025)));

    final incoming = json.encode({
      'app': 'still_life',
      'version': '1.0',
      'data': {
        'items': [
          {
            'id': 'iB', 'name': 'B', 'categoryId': 'cat1', 'roomId': 'room1',
            'createdAt': DateTime(2026).toIso8601String(),
            'modifiedAt': DateTime(2026).toIso8601String(), 'hlc': 'z',
          }
        ],
        'photos': [
          {
            'id': 'phB', 'itemId': 'iB', 'filePath': '',
            'capturedAt': DateTime(2026).toIso8601String(),
            'createdAt': DateTime(2026).toIso8601String(),
            'modifiedAt': DateTime(2026).toIso8601String(), 'hlc': 'z',
          }
        ],
      },
    });

    // Fire the export and a concurrent import; whichever snapshot the export
    // captures, it must be all-or-nothing for item B — never B's photo alone.
    final exportFuture = exporter.exportToJson();
    final importFuture = importer.importFromJson(incoming, lww: true);
    final jsonStr = await exportFuture;
    await importFuture;

    final data = (json.decode(jsonStr) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    final itemIds =
        (data['items'] as List).map((e) => (e as Map)['id']).toSet();
    final photoItemIds =
        (data['photos'] as List).map((e) => (e as Map)['itemId']).toSet();
    expect(photoItemIds.difference(itemIds), isEmpty,
        reason: 'export contained a photo whose parent item was not exported');
  });

  test('export includes isDeleted on all _toMap methods', () async {
    // Seed one row per exported table with isDeleted = true.
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'i1',
            name: 'Deleted item',
            categoryId: 'cat1',
            roomId: 'room1',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
            isDeleted: const Value(true),
          ),
        );
    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(
            id: 't1',
            name: 'old-tag',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
            isDeleted: const Value(true),
          ),
        );

    final jsonStr = await exporter.exportToJson();
    final decoded = json.decode(jsonStr) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;

    // Every top-level list-of-rows entry should include isDeleted on each row.
    for (final key in const [
      'properties',
      'rooms',
      'categories',
      'items',
      'tags',
    ]) {
      final rows = data[key] as List<dynamic>;
      for (final r in rows) {
        expect(
          (r as Map<String, dynamic>).containsKey('isDeleted'),
          isTrue,
          reason: '$key row missing isDeleted: $r',
        );
      }
    }

    // Specifically: tombstoned item/tag round-trip with isDeleted=true.
    final items = data['items'] as List<dynamic>;
    expect((items.first as Map<String, dynamic>)['isDeleted'], isTrue);
    final tags = data['tags'] as List<dynamic>;
    expect((tags.first as Map<String, dynamic>)['isDeleted'], isTrue);
  });

  test('import preserves isDeleted tombstones (no resurrection)', () async {
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'ghost',
            name: 'Ghost',
            categoryId: 'cat1',
            roomId: 'room1',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
            isDeleted: const Value(true),
          ),
        );

    final jsonStr = await exporter.exportToJson();

    // Wipe the source DB to simulate a fresh target device.
    await db.delete(db.items).go();

    // Reseed dependencies that the import needs.
    // (properties/rooms/categories still present from setUp.)

    final result = await importer.importFromJson(jsonStr);
    expect(result.isSuccess, isTrue);

    final reloaded = await (db.select(
      db.items,
    )..where((t) => t.id.equals('ghost'))).getSingle();
    expect(
      reloaded.isDeleted,
      isTrue,
      reason: 'imported tombstone must stay soft-deleted',
    );
  });

  test('import coerces integer quantity/lowStockThreshold from JSON', () async {
    // Hand-craft a JSON payload where quantity is an int (5) and
    // lowStockThreshold is an int (2). Previously `as double?` would throw.
    final payload = {
      'version': '1.0',
      'app': 'still_life',
      'exportedAt': DateTime(2025).toIso8601String(),
      'data': {
        'properties': [],
        'rooms': [],
        'storageContainers': [],
        'categories': [],
        'tags': [],
        'profiles': [],
        'items': [
          {
            'id': 'num-item',
            'name': 'Batteries',
            'description': '',
            'categoryId': 'cat1',
            'roomId': 'room1',
            'createdAt': DateTime(2025).toIso8601String(),
            'modifiedAt': DateTime(2025).toIso8601String(),
            'quantity': 5, // int on the wire
            'quantityUnit': 'pack',
            'lowStockThreshold': 2, // int on the wire
          },
        ],
        'itemTags': [],
        'photos': [],
        'receipts': [],
        'priceHistory': [],
        'policies': [],
        'maintenanceLogs': [],
      },
    };
    final result = await importer.importFromJson(json.encode(payload));
    expect(
      result.isSuccess,
      isTrue,
      reason: 'import should tolerate int → double',
    );

    final row = await (db.select(
      db.items,
    )..where((t) => t.id.equals('num-item'))).getSingle();
    expect(row.quantity, 5.0);
    expect(row.lowStockThreshold, 2.0);
  });

  test('brand/model/asin round-trip through JSON export + import', () async {
    await db.into(db.items).insert(
          ItemsCompanion.insert(
            id: 'hp',
            name: 'Headphones',
            categoryId: 'cat1',
            roomId: 'room1',
            brand: const Value('Sony'),
            model: const Value('WH-1000XM4'),
            asin: const Value('B0863TXGM3'),
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );

    final exported = await exporter.exportToJson();
    final data = (json.decode(exported) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    final itemMap = (data['items'] as List).single as Map<String, dynamic>;
    expect(itemMap['brand'], 'Sony');
    expect(itemMap['model'], 'WH-1000XM4');
    expect(itemMap['asin'], 'B0863TXGM3');

    await db.delete(db.items).go();
    final r = await importer.importFromJson(exported);
    expect(r.isSuccess, isTrue);
    final row = await (db.select(db.items)..where((t) => t.id.equals('hp')))
        .getSingle();
    expect(row.brand, 'Sony');
    expect(row.model, 'WH-1000XM4');
    expect(row.asin, 'B0863TXGM3');
  });

  test('restoring an old backup without brand/model/asin yields nulls',
      () async {
    // Pre-v13 backups carry no identity keys; the restore must succeed
    // and simply leave the new columns null.
    final payload = {
      'version': '1.0',
      'app': 'still_life',
      'exportedAt': DateTime(2025).toIso8601String(),
      'data': {
        'items': [
          {
            'id': 'old-item',
            'name': 'Legacy lamp',
            'description': '',
            'categoryId': 'cat1',
            'roomId': 'room1',
            'createdAt': DateTime(2025).toIso8601String(),
            'modifiedAt': DateTime(2025).toIso8601String(),
            // no brand / model / asin keys — older backups
          },
        ],
      },
    };
    final r = await importer.importFromJson(json.encode(payload));
    expect(r.isSuccess, isTrue);

    final row = await (db.select(db.items)
          ..where((t) => t.id.equals('old-item')))
        .getSingle();
    expect(row.brand, isNull);
    expect(row.model, isNull);
    expect(row.asin, isNull);
  });

  test('receiptId and its Receipts row round-trip through JSON '
      'export + import', () async {
    await db.into(db.receipts).insert(
          ReceiptsCompanion.insert(
            id: 'rcpt-1',
            photoPath: '',
            storeName: const Value('Kroger'),
            purchaseDate: Value(DateTime(2026, 7, 2)),
            totalAmountCents: const Value(1648),
            ocrText: const Value('KROGER\nCoffee 12.99'),
            createdAt: DateTime(2026),
          ),
        );
    await db.into(db.items).insert(
          ItemsCompanion.insert(
            id: 'coffee',
            name: 'Coffee Beans',
            categoryId: 'cat1',
            roomId: 'room1',
            receiptId: const Value('rcpt-1'),
            createdAt: DateTime(2026),
            modifiedAt: DateTime(2026),
          ),
        );

    final exported = await exporter.exportToJson();
    final data = (json.decode(exported) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    final itemMap = (data['items'] as List).single as Map<String, dynamic>;
    expect(itemMap['receiptId'], 'rcpt-1');
    final receiptMap =
        (data['receipts'] as List).single as Map<String, dynamic>;
    expect(receiptMap['storeName'], 'Kroger');
    expect(receiptMap['totalAmount'], 16.48);

    await db.delete(db.items).go();
    await db.delete(db.receipts).go();
    final r = await importer.importFromJson(exported);
    expect(r.isSuccess, isTrue);

    final itemRow = await (db.select(db.items)
          ..where((t) => t.id.equals('coffee')))
        .getSingle();
    expect(itemRow.receiptId, 'rcpt-1');
    final receiptRow = await (db.select(db.receipts)
          ..where((t) => t.id.equals('rcpt-1')))
        .getSingle();
    expect(receiptRow.storeName, 'Kroger');
    expect(receiptRow.totalAmountCents, 1648);
    expect(receiptRow.ocrText, 'KROGER\nCoffee 12.99');
    expect(receiptRow.itemId, isNull,
        reason: 'multi-item receipts keep itemId null; the link is on Items');
  });

  test('restoring a pre-v14 backup without receiptId yields null', () async {
    final payload = {
      'version': '1.0',
      'app': 'still_life',
      'exportedAt': DateTime(2025).toIso8601String(),
      'data': {
        'items': [
          {
            'id': 'old-item',
            'name': 'Legacy lamp',
            'description': '',
            'categoryId': 'cat1',
            'roomId': 'room1',
            'createdAt': DateTime(2025).toIso8601String(),
            'modifiedAt': DateTime(2025).toIso8601String(),
            // no receiptId key — older backups
          },
        ],
      },
    };
    final r = await importer.importFromJson(json.encode(payload));
    expect(r.isSuccess, isTrue);

    final row = await (db.select(db.items)
          ..where((t) => t.id.equals('old-item')))
        .getSingle();
    expect(row.receiptId, isNull);
  });

  test('loans round-trip through JSON export + import', () async {
    // Seed an item and one active + one returned loan + one tombstoned loan.
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'cam',
            name: 'Camera',
            categoryId: 'cat1',
            roomId: 'room1',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
    await db
        .into(db.loans)
        .insert(
          LoansCompanion.insert(
            id: 'l-active',
            itemId: 'cam',
            borrowerName: 'Alice',
            expectedReturnDate: Value(DateTime(2025, 6, 1)),
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
    await db
        .into(db.loans)
        .insert(
          LoansCompanion.insert(
            id: 'l-returned',
            itemId: 'cam',
            borrowerName: 'Bob',
            returnedAt: Value(DateTime(2025, 5)),
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
    await db
        .into(db.loans)
        .insert(
          LoansCompanion.insert(
            id: 'l-deleted',
            itemId: 'cam',
            borrowerName: 'Carol',
            isDeleted: const Value(true),
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );

    final exported = await exporter.exportToJson();
    final parsed = json.decode(exported) as Map<String, dynamic>;
    final loansList =
        (parsed['data']! as Map<String, dynamic>)['loans'] as List;
    expect(loansList, hasLength(3), reason: 'all loans must be exported');
    expect(
      loansList.any((l) => (l as Map)['isDeleted'] == true),
      isTrue,
      reason: 'tombstones must round-trip',
    );

    // Wipe and reimport.
    await db.delete(db.loans).go();
    final r = await importer.importFromJson(exported);
    expect(r.isSuccess, isTrue);
    final imported = await db.select(db.loans).get();
    expect(imported, hasLength(3));
    final byId = {for (final l in imported) l.id: l};
    expect(byId['l-active']!.borrowerName, 'Alice');
    expect(byId['l-active']!.expectedReturnDate, DateTime(2025, 6, 1));
    expect(byId['l-returned']!.returnedAt, DateTime(2025, 5));
    expect(byId['l-deleted']!.isDeleted, isTrue);
    // Verify the summary counts the loans separately.
    r.when(
      success: (s) => expect(s.loans, 3),
      failure: (_) => fail('import failed'),
    );
  });

  test('import tolerates payload with no loans key (back-compat)', () async {
    final payload = {
      'version': '1.0',
      'app': 'still_life',
      'exportedAt': DateTime(2025).toIso8601String(),
      'data': {
        'properties': [],
        'rooms': [],
        'storageContainers': [],
        'categories': [],
        'tags': [],
        'profiles': [],
        'items': [],
        'itemTags': [],
        'photos': [],
        'receipts': [],
        'priceHistory': [],
        'policies': [],
        'maintenanceLogs': [],
        // no 'loans' key — older backups
      },
    };
    final r = await importer.importFromJson(json.encode(payload));
    expect(r.isSuccess, isTrue);
  });

  test('appraisals round-trip through JSON export + import', () async {
    // Seed one item and one appraisal.
    await db
        .into(db.items)
        .insert(
          ItemsCompanion.insert(
            id: 'tv',
            name: 'TV',
            categoryId: 'cat1',
            roomId: 'room1',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
    final queriedAt = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = DateTime.now()
        .add(const Duration(days: 30))
        .millisecondsSinceEpoch;
    await db
        .into(db.appraisals)
        .insert(
          AppraisalsCompanion.insert(
            id: 'app1',
            itemId: 'tv',
            mode: 'resale',
            valueCents: 27550,
            itemModelKey: 'tv|good',
            queriedAt: queriedAt,
            expiresAt: expiresAt,
            currency: const Value('USD'),
            confidence: const Value(0.75),
            sourceUrls: const Value('[{"url":"https://x","title":"X"}]'),
          ),
        );

    final exported = await exporter.exportToJson();
    final parsed = json.decode(exported) as Map<String, dynamic>;
    final appraisalsList =
        (parsed['data']! as Map<String, dynamic>)['appraisals'] as List;
    expect(appraisalsList, hasLength(1));
    expect(appraisalsList.first['mode'], 'resale');

    // Wipe and reimport.
    await db.delete(db.appraisals).go();
    final r = await importer.importFromJson(exported);
    expect(r.isSuccess, isTrue);
    final rows = await db.select(db.appraisals).get();
    expect(rows, hasLength(1));
    expect(rows.first.valueCents, 27550);
    expect(rows.first.confidence, 0.75);
    expect(rows.first.sourceUrls, contains('https://x'));
  });

  Future<void> seedItem(String id) async {
    await db.into(db.items).insert(
          ItemsCompanion.insert(
            id: id,
            name: 'Camera',
            categoryId: 'cat1',
            roomId: 'room1',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
  }

  test(
    'v12 blob-backed photo (empty filePath) round-trips metadata',
    () async {
      // Since v12, photo bytes live in the DB and filePath is ''. Export
      // still ships photosIncluded:false, so import must recreate the row
      // (metadata only, null bytes) — and the empty path must not trip the
      // path-traversal guard.
      await seedItem('item1');
      await db.photoDao.insertPhoto(
        PhotosCompanion.insert(
          id: 'photo1',
          itemId: 'item1',
          filePath: '',
          bytes: Value(Uint8List.fromList([1, 2, 3])),
          capturedAt: DateTime(2025),
          createdAt: DateTime(2025),
          modifiedAt: DateTime(2025),
        ),
      );

      final exported = await exporter.exportToJson();
      expect(
        (json.decode(exported) as Map<String, dynamic>)['photosIncluded'],
        isFalse,
        reason: 'photo bytes must not travel in exports (unchanged by v12)',
      );

      await db.delete(db.photos).go();
      final result = await importer.importFromJson(exported);
      expect(result.isSuccess, isTrue);

      final rows = await db.select(db.photos).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'photo1');
      expect(rows.first.filePath, isEmpty);
      expect(rows.first.bytes, isNull,
          reason: 'bytes are device-local; import carries metadata only');
    },
  );

  test('pre-v12 export with a legacy absolute filePath still imports',
      () async {
    // Old backups carry device paths that don't exist here. The row must
    // import (photo shows a placeholder) rather than crash or be dropped.
    await seedItem('item1');
    final legacyExport = json.encode({
      'version': '1.0',
      'app': 'still_life',
      'exportedAt': DateTime(2025).toIso8601String(),
      'photosIncluded': false,
      'data': {
        'photos': [
          {
            'id': 'photo-legacy',
            'itemId': 'item1',
            'filePath': '/some/other/device/photos/item1/a.jpg',
            'isPrimary': true,
            'source': 'camera',
            'capturedAt': DateTime(2025).toIso8601String(),
            'createdAt': DateTime(2025).toIso8601String(),
            'modifiedAt': DateTime(2025).toIso8601String(),
          },
        ],
      },
    });

    final result = await importer.importFromJson(legacyExport);
    expect(result.isSuccess, isTrue);

    final rows = await db.select(db.photos).get();
    expect(rows, hasLength(1));
    expect(rows.first.filePath, '/some/other/device/photos/item1/a.jpg');
    expect(rows.first.bytes, isNull);
  });
}

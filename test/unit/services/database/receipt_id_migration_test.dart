import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:still_life/services/database/database.dart';

import '../../../test_setup.dart';

/// Schema v13 → v14 adds one nullable TEXT column to items — `receipt_id`
/// — so a receipt-sourced import can link every accepted item to the ONE
/// Receipts row persisted for the batch (Receipts.itemId stays null for
/// multi-item receipts; the link lives on Items).
///
/// The migration must:
///  * add the column as nullable TEXT,
///  * preserve every existing row untouched (new column null),
///  * leave fresh installs (onCreate) with the column present.
void main() {
  ensureSqlite3();

  /// Builds an in-memory database shaped like a real schema-v13 install:
  /// only the items table (the single table the v14 step touches), at its
  /// exact v13 shape, plus one row.
  raw.Database buildV13Database() {
    final db = raw.sqlite3.openInMemory();
    db.execute('''
      CREATE TABLE items (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category_id TEXT NOT NULL,
        room_id TEXT NOT NULL,
        purchase_date INTEGER,
        purchase_price REAL,
        current_value REAL,
        replacement_cost REAL,
        condition TEXT,
        serial_number TEXT,
        warranty_expiration INTEGER,
        container_id TEXT,
        barcode TEXT,
        store_url TEXT,
        notes TEXT,
        is_insured INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        modified_at INTEGER NOT NULL,
        node_id TEXT NOT NULL DEFAULT '',
        hlc TEXT NOT NULL DEFAULT '',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        quantity REAL,
        quantity_unit TEXT,
        low_stock_threshold REAL,
        creator_profile_id TEXT,
        owner_profile_id TEXT,
        brand TEXT,
        model TEXT,
        asin TEXT
      )
    ''');
    db.execute(
      'INSERT INTO items '
      '(id, name, category_id, room_id, brand, created_at, modified_at) '
      "VALUES ('item-1', 'Old drill', 'cat-1', 'room-1', 'Bosch', 0, 0)",
    );
    db.execute('PRAGMA user_version = 13');
    return db;
  }

  group('v13 → v14 receiptId migration', () {
    late raw.Database rawDb;
    late AppDatabase db;

    setUp(() {
      rawDb = buildV13Database();
      db = AppDatabase(
        NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
      );
    });

    tearDown(() async {
      await db.close();
      rawDb.dispose();
    });

    test('bumps user_version to the current schema and adds the receipt_id column', () async {
      await db.select(db.items).get(); // triggers open + migration

      expect(rawDb.select('PRAGMA user_version').single.values.first,
          db.schemaVersion);
      final cols = rawDb
          .select('PRAGMA table_info(items)')
          .map((r) => r['name'])
          .toList();
      expect(cols, contains('receipt_id'));
    });

    test('preserves existing rows with null receiptId', () async {
      final items = await db.select(db.items).get();

      expect(items, hasLength(1), reason: 'migration must not drop rows');
      final item = items.single;
      expect(item.id, 'item-1');
      expect(item.name, 'Old drill');
      expect(item.brand, 'Bosch');
      expect(item.receiptId, isNull);
    });
  });

  group('fresh v14 database', () {
    test('item insert with receiptId roundtrips', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final now = DateTime(2026);

      await db.into(db.properties).insert(PropertiesCompanion.insert(
          id: 'prop-1', name: 'Home', createdAt: now, modifiedAt: now));
      await db.into(db.rooms).insert(RoomsCompanion.insert(
          id: 'room-1',
          propertyId: 'prop-1',
          name: 'Garage',
          createdAt: now,
          modifiedAt: now));
      await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat-1', name: 'Tools', createdAt: now, modifiedAt: now));
      await db.into(db.receipts).insert(ReceiptsCompanion.insert(
          id: 'rcpt-1',
          photoPath: '',
          storeName: const Value('Home Depot'),
          createdAt: now));
      await db.into(db.items).insert(ItemsCompanion.insert(
          id: 'item-1',
          name: 'Impact driver',
          categoryId: 'cat-1',
          roomId: 'room-1',
          receiptId: const Value('rcpt-1'),
          createdAt: now,
          modifiedAt: now));

      final row = await (db.select(db.items)
            ..where((t) => t.id.equals('item-1')))
          .getSingle();
      expect(row.receiptId, 'rcpt-1');
    });
  });
}

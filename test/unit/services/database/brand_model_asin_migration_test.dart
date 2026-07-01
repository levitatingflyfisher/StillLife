import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:still_life/services/database/database.dart';

import '../../../test_setup.dart';

/// Schema v12 → v13 adds three nullable TEXT columns to items —
/// `brand`, `model`, `asin` — so AI suggestions, barcode lookups, and
/// future marketplace imports have real columns instead of smuggling
/// identity into name/notes.
///
/// The migration must:
///  * add the columns as nullable TEXT,
///  * preserve every existing row untouched (new columns null),
///  * leave fresh installs (onCreate) with the columns present.
void main() {
  ensureSqlite3();

  /// Builds an in-memory database shaped like a real schema-v12 install:
  /// only the items table (the single table the v13 step touches), at its
  /// exact v12 shape, plus one row.
  raw.Database buildV12Database() {
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
        owner_profile_id TEXT
      )
    ''');
    db.execute(
      'INSERT INTO items '
      '(id, name, category_id, room_id, serial_number, created_at, modified_at) '
      "VALUES ('item-1', 'Old drill', 'cat-1', 'room-1', 'SN-42', 0, 0)",
    );
    db.execute('PRAGMA user_version = 12');
    return db;
  }

  group('v12 → v13 brand/model/asin migration', () {
    late raw.Database rawDb;
    late AppDatabase db;

    setUp(() {
      rawDb = buildV12Database();
      db = AppDatabase(
        NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false),
      );
    });

    tearDown(() async {
      await db.close();
      rawDb.dispose();
    });

    test('bumps user_version to the current schema and adds the three columns',
        () async {
      await db.select(db.items).get(); // triggers open + migration

      expect(rawDb.select('PRAGMA user_version').single.values.first,
          db.schemaVersion);
      final cols = rawDb
          .select('PRAGMA table_info(items)')
          .map((r) => r['name'])
          .toList();
      expect(cols, containsAll(['brand', 'model', 'asin']));
    });

    test('preserves existing rows with null brand/model/asin', () async {
      final items = await db.select(db.items).get();

      expect(items, hasLength(1), reason: 'migration must not drop rows');
      final item = items.single;
      expect(item.id, 'item-1');
      expect(item.name, 'Old drill');
      expect(item.serialNumber, 'SN-42');
      expect(item.brand, isNull);
      expect(item.model, isNull);
      expect(item.asin, isNull);
    });
  });

  group('fresh v13 database', () {
    test('item insert with brand/model/asin roundtrips', () async {
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
      await db.into(db.items).insert(ItemsCompanion.insert(
          id: 'item-1',
          name: 'Impact driver',
          categoryId: 'cat-1',
          roomId: 'room-1',
          brand: const Value('Bosch'),
          model: const Value('GDX 18V-200'),
          asin: const Value('B0ABCDEF12'),
          createdAt: now,
          modifiedAt: now));

      final row = await (db.select(db.items)
            ..where((t) => t.id.equals('item-1')))
          .getSingle();
      expect(row.brand, 'Bosch');
      expect(row.model, 'GDX 18V-200');
      expect(row.asin, 'B0ABCDEF12');
    });
  });
}

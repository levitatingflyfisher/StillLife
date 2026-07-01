import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:still_life/services/database/database.dart';

import '../../../test_setup.dart';

/// Schema v14 → v15 moves every monetary column from REAL dollars to
/// INTEGER cents so money arithmetic is exact. The migration must:
///  * rebuild the six money tables with `*_cents INTEGER` columns,
///    converting each stored dollar value via ROUND(x * 100),
///  * preserve NULLs (no price stays no price) and every non-money column,
///  * keep foreign keys intact across the items rebuild,
///  * recreate the items FTS triggers and rebuild the FTS index — search
///    must still work, including for rows inserted AFTER the migration.
void main() {
  ensureSqlite3();

  /// Builds an in-memory database at the exact v14 shape (DDL captured from
  /// a real v14 install), seeded with dollar values including the sub-cent
  /// junk the old unrounded policy/maintenance write path could produce.
  raw.Database buildV14Database() {
    final db = raw.sqlite3.openInMemory();
    db.execute('''
      CREATE TABLE "properties" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "address" TEXT NULL, "type" TEXT NOT NULL DEFAULT 'Home', "created_at" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL, "node_id" TEXT NOT NULL DEFAULT '', "hlc" TEXT NOT NULL DEFAULT '', "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), PRIMARY KEY ("id"))
    ''');
    db.execute('''
      CREATE TABLE "rooms" ("id" TEXT NOT NULL, "property_id" TEXT NOT NULL REFERENCES properties (id), "parent_id" TEXT NULL, "name" TEXT NOT NULL, "floor" TEXT NULL, "sort_order" INTEGER NOT NULL DEFAULT 0, "photo_path" TEXT NULL, "created_at" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL, "node_id" TEXT NOT NULL DEFAULT '', "hlc" TEXT NOT NULL DEFAULT '', "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), PRIMARY KEY ("id"))
    ''');
    db.execute('''
      CREATE TABLE "categories" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "parent_id" TEXT NULL, "icon_code_point" INTEGER NULL, "created_at" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL, "node_id" TEXT NOT NULL DEFAULT '', "hlc" TEXT NOT NULL DEFAULT '', "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), PRIMARY KEY ("id"))
    ''');
    db.execute('''
      CREATE TABLE "profiles" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "color_hex" TEXT NOT NULL DEFAULT '#6750A4', "avatar_emoji" TEXT NOT NULL DEFAULT '👤', "is_default" INTEGER NOT NULL DEFAULT 0 CHECK ("is_default" IN (0, 1)), "created_at" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL, "node_id" TEXT NOT NULL DEFAULT '', "hlc" TEXT NOT NULL DEFAULT '', "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), PRIMARY KEY ("id"))
    ''');
    db.execute('''
      CREATE TABLE "items" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "description" TEXT NOT NULL DEFAULT '', "category_id" TEXT NOT NULL REFERENCES categories (id), "room_id" TEXT NOT NULL REFERENCES rooms (id), "purchase_date" INTEGER NULL, "purchase_price" REAL NULL, "current_value" REAL NULL, "replacement_cost" REAL NULL, "condition" TEXT NULL, "serial_number" TEXT NULL, "warranty_expiration" INTEGER NULL, "container_id" TEXT NULL, "barcode" TEXT NULL, "store_url" TEXT NULL, "notes" TEXT NULL, "is_insured" INTEGER NOT NULL DEFAULT 0 CHECK ("is_insured" IN (0, 1)), "created_at" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL, "node_id" TEXT NOT NULL DEFAULT '', "hlc" TEXT NOT NULL DEFAULT '', "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), "quantity" REAL NULL, "quantity_unit" TEXT NULL, "low_stock_threshold" REAL NULL, "creator_profile_id" TEXT NULL REFERENCES profiles (id), "owner_profile_id" TEXT NULL REFERENCES profiles (id), "brand" TEXT NULL, "model" TEXT NULL, "asin" TEXT NULL, "receipt_id" TEXT NULL, PRIMARY KEY ("id"))
    ''');
    db.execute('''
      CREATE TABLE "receipts" ("id" TEXT NOT NULL, "item_id" TEXT NULL REFERENCES items (id), "photo_path" TEXT NOT NULL, "photo_bytes" BLOB NULL, "store_name" TEXT NULL, "purchase_date" INTEGER NULL, "total_amount" REAL NULL, "ocr_text" TEXT NULL, "node_id" TEXT NOT NULL DEFAULT '', "hlc" TEXT NOT NULL DEFAULT '', "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"))
    ''');
    db.execute('''
      CREATE TABLE "price_history_entries" ("id" TEXT NOT NULL, "item_id" TEXT NOT NULL REFERENCES items (id), "price" REAL NOT NULL, "source" TEXT NOT NULL, "recorded_at" INTEGER NOT NULL, "node_id" TEXT NOT NULL DEFAULT '', "hlc" TEXT NOT NULL DEFAULT '', "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), PRIMARY KEY ("id"))
    ''');
    db.execute('''
      CREATE TABLE "policies" ("id" TEXT NOT NULL, "property_id" TEXT NOT NULL REFERENCES properties (id), "provider" TEXT NOT NULL, "policy_number" TEXT NULL, "coverage_amount" REAL NULL, "deductible" REAL NULL, "premium" REAL NULL, "expiry_date" INTEGER NULL, "created_at" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL, "node_id" TEXT NOT NULL DEFAULT '', "hlc" TEXT NOT NULL DEFAULT '', "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), PRIMARY KEY ("id"))
    ''');
    db.execute('''
      CREATE TABLE "maintenance_logs" ("id" TEXT NOT NULL, "item_id" TEXT NULL REFERENCES items (id), "property_id" TEXT NULL REFERENCES properties (id), "title" TEXT NOT NULL, "description" TEXT NULL, "cost" REAL NULL, "performed_at" INTEGER NOT NULL, "next_due_at" INTEGER NULL, "serviced_by" TEXT NULL, "created_at" INTEGER NOT NULL, "modified_at" INTEGER NOT NULL, "node_id" TEXT NOT NULL DEFAULT '', "hlc" TEXT NOT NULL DEFAULT '', "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), PRIMARY KEY ("id"))
    ''');
    db.execute('''
      CREATE TABLE "appraisals" ("id" TEXT NOT NULL, "item_id" TEXT NOT NULL REFERENCES items (id), "mode" TEXT NOT NULL, "value" REAL NOT NULL, "currency" TEXT NOT NULL DEFAULT 'USD', "confidence" REAL NOT NULL DEFAULT 0.5, "source_urls" TEXT NOT NULL DEFAULT '[]', "item_model_key" TEXT NOT NULL, "country_code" TEXT NOT NULL DEFAULT 'US', "queried_at" INTEGER NOT NULL, "expires_at" INTEGER NOT NULL, "node_id" TEXT NOT NULL DEFAULT '', "hlc" TEXT NOT NULL DEFAULT '', "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), PRIMARY KEY ("id"))
    ''');
    db.execute('''
      CREATE VIRTUAL TABLE items_fts USING fts5(
        name, description, notes, serial_number, barcode,
        content=items, content_rowid=rowid
      )
    ''');
    db.execute('''
      CREATE TRIGGER items_fts_insert AFTER INSERT ON items BEGIN
        INSERT INTO items_fts(rowid, name, description, notes, serial_number, barcode)
        VALUES (new.rowid, new.name, new.description, new.notes, new.serial_number, new.barcode);
      END
    ''');
    db.execute('''
      CREATE TRIGGER items_fts_update AFTER UPDATE ON items BEGIN
        INSERT INTO items_fts(items_fts, rowid, name, description, notes, serial_number, barcode)
        VALUES ('delete', old.rowid, old.name, old.description, old.notes, old.serial_number, old.barcode);
        INSERT INTO items_fts(rowid, name, description, notes, serial_number, barcode)
        VALUES (new.rowid, new.name, new.description, new.notes, new.serial_number, new.barcode);
      END
    ''');
    db.execute('''
      CREATE TRIGGER items_fts_delete AFTER DELETE ON items BEGIN
        INSERT INTO items_fts(items_fts, rowid, name, description, notes, serial_number, barcode)
        VALUES ('delete', old.rowid, old.name, old.description, old.notes, old.serial_number, old.barcode);
      END
    ''');

    db.execute(
      "INSERT INTO properties (id, name, created_at, modified_at) VALUES ('prop-1', 'Home', 0, 0)",
    );
    db.execute(
      "INSERT INTO rooms (id, property_id, name, created_at, modified_at) VALUES ('room-1', 'prop-1', 'Study', 0, 0)",
    );
    db.execute(
      "INSERT INTO categories (id, name, created_at, modified_at) VALUES ('cat-1', 'Electronics', 0, 0)",
    );
    // Inserted through the live triggers, so items_fts is populated exactly
    // as on a real device.
    db.execute(
      'INSERT INTO items (id, name, category_id, room_id, purchase_price, current_value, replacement_cost, created_at, modified_at) VALUES '
      "('item-priced', 'Canon camera', 'cat-1', 'room-1', 1050.0, 0.01, NULL, 0, 0), "
      "('item-free', 'Shoebox of cables', 'cat-1', 'room-1', NULL, NULL, NULL, 0, 0)",
    );
    db.execute(
      'INSERT INTO receipts (id, item_id, photo_path, store_name, total_amount, created_at) VALUES '
      "('rcpt-priced', 'item-priced', '', 'Best Buy', 16.48, 0), "
      "('rcpt-free', 'item-priced', '', NULL, NULL, 0)",
    );
    db.execute(
      'INSERT INTO price_history_entries (id, item_id, price, source, recorded_at) VALUES '
      "('ph-1', 'item-priced', 449.99, 'manual', 0)",
    );
    db.execute(
      'INSERT INTO policies (id, property_id, provider, coverage_amount, deductible, premium, created_at, modified_at) VALUES '
      "('pol-1', 'prop-1', 'Acme Mutual', 250000.0, 1000.0, 87.5, 0, 0)",
    );
    // 123.456: sub-cent junk the old raw double.tryParse write path allowed.
    db.execute(
      'INSERT INTO maintenance_logs (id, item_id, title, cost, performed_at, created_at, modified_at) VALUES '
      "('mnt-1', 'item-priced', 'Sensor cleaning', 123.456, 0, 0, 0)",
    );
    db.execute(
      'INSERT INTO appraisals (id, item_id, mode, value, item_model_key, queried_at, expires_at) VALUES '
      "('apr-1', 'item-priced', 'resale', 275.5, 'canon-camera', 0, 0)",
    );
    db.execute('PRAGMA user_version = 14');
    return db;
  }

  group('v14 → v15 money cents migration', () {
    late raw.Database rawDb;
    late AppDatabase db;

    setUp(() {
      rawDb = buildV14Database();
      db = AppDatabase(NativeDatabase.opened(rawDb, closeUnderlyingOnClose: false));
    });

    tearDown(() async {
      await db.close();
      rawDb.dispose();
    });

    Future<void> open() => db.customSelect('SELECT 1').get();

    test('bumps user_version and swaps every money column to *_cents INTEGER',
        () async {
      await open();

      expect(rawDb.select('PRAGMA user_version').single.values.first,
          db.schemaVersion);

      final expectations = <String, List<String>>{
        'items': [
          'purchase_price_cents',
          'current_value_cents',
          'replacement_cost_cents',
        ],
        'receipts': ['total_amount_cents'],
        'price_history_entries': ['price_cents'],
        'policies': ['coverage_amount_cents', 'deductible_cents', 'premium_cents'],
        'maintenance_logs': ['cost_cents'],
        'appraisals': ['value_cents'],
      };
      final dollarNames = {
        'purchase_price', 'current_value', 'replacement_cost', 'total_amount',
        'price', 'coverage_amount', 'deductible', 'premium', 'cost', 'value',
      };
      for (final entry in expectations.entries) {
        final info = rawDb.select('PRAGMA table_info(${entry.key})');
        final byName = {for (final r in info) r['name'] as String: r['type']};
        for (final col in entry.value) {
          expect(byName[col], 'INTEGER',
              reason: '${entry.key}.$col must be INTEGER cents');
        }
        expect(byName.keys.where(dollarNames.contains), isEmpty,
            reason: '${entry.key} must not keep a dollar REAL column');
      }
    });

    test('converts stored dollars to cents exactly, preserving NULLs', () async {
      await open();

      final priced = rawDb
          .select("SELECT * FROM items WHERE id = 'item-priced'")
          .single;
      expect(priced['purchase_price_cents'], 105000);
      expect(priced['current_value_cents'], 1);
      expect(priced['replacement_cost_cents'], isNull);
      expect(priced['name'], 'Canon camera', reason: 'non-money columns survive');

      final free = rawDb.select("SELECT * FROM items WHERE id = 'item-free'").single;
      expect(free['purchase_price_cents'], isNull);
      expect(free['current_value_cents'], isNull);

      final rcpt = rawDb
          .select("SELECT * FROM receipts WHERE id = 'rcpt-priced'")
          .single;
      expect(rcpt['total_amount_cents'], 1648);
      expect(rcpt['store_name'], 'Best Buy');
      expect(
          rawDb
              .select("SELECT total_amount_cents FROM receipts WHERE id = 'rcpt-free'")
              .single
              .values
              .first,
          isNull);

      expect(rawDb.select('SELECT price_cents FROM price_history_entries').single
          .values.first, 44999);

      final pol = rawDb.select('SELECT * FROM policies').single;
      expect(pol['coverage_amount_cents'], 25000000);
      expect(pol['deductible_cents'], 100000);
      expect(pol['premium_cents'], 8750);

      expect(rawDb.select('SELECT cost_cents FROM maintenance_logs').single
          .values.first, 12346,
          reason: 'sub-cent legacy junk rounds to whole cents');

      final apr = rawDb.select('SELECT * FROM appraisals').single;
      expect(apr['value_cents'], 27550);
      expect(apr['currency'], 'USD');
      expect(apr['confidence'], 0.5, reason: 'confidence is not money');
    });

    test('keeps foreign keys intact across the items rebuild', () async {
      await open();
      expect(rawDb.select('PRAGMA foreign_key_check'), isEmpty);
    });

    test('search still works: FTS index rebuilt and triggers recreated',
        () async {
      await open();

      // Pre-migration rows are findable (index rebuilt over the new table).
      expect(
        rawDb.select("SELECT rowid FROM items_fts WHERE items_fts MATCH 'camera'"),
        hasLength(1),
      );

      // Rows inserted AFTER the migration are findable (triggers recreated).
      rawDb.execute(
        'INSERT INTO items (id, name, category_id, room_id, created_at, modified_at) VALUES '
        "('item-new', 'Telescope tripod', 'cat-1', 'room-1', 0, 0)",
      );
      expect(
        rawDb.select("SELECT rowid FROM items_fts WHERE items_fts MATCH 'telescope'"),
        hasLength(1),
      );
      final triggers = rawDb
          .select("SELECT name FROM sqlite_master WHERE type = 'trigger' AND tbl_name = 'items'")
          .map((r) => r['name'])
          .toSet();
      expect(triggers,
          {'items_fts_insert', 'items_fts_update', 'items_fts_delete'});
    });
  });
}

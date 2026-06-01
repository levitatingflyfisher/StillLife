import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'daos/item_dao.dart';
import 'daos/category_dao.dart';
import 'daos/location_dao.dart';
import 'daos/tag_dao.dart';
import 'daos/photo_dao.dart';
import 'daos/receipt_dao.dart';
import 'daos/price_history_dao.dart';
import 'daos/policy_dao.dart';
import 'daos/maintenance_dao.dart';
import 'daos/container_dao.dart';
import 'daos/loan_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/appraisal_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Properties,
    Rooms,
    StorageContainers,
    Categories,
    Items,
    Tags,
    ItemTags,
    Photos,
    Receipts,
    PriceHistoryEntries,
    Policies,
    MaintenanceLogs,
    VideoAnalyses,
    ProductLookupCache,
    Loans,
    Profiles,
    Appraisals,
  ],
  daos: [
    ItemDao,
    CategoryDao,
    LocationDao,
    TagDao,
    PhotoDao,
    ReceiptDao,
    PriceHistoryDao,
    PolicyDao,
    MaintenanceDao,
    ContainerDao,
    LoanDao,
    ProfileDao,
    AppraisalDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Production constructor — uses native SQLite file.
  factory AppDatabase.production() {
    return AppDatabase(_openConnection());
  }

  /// In-memory constructor for testing.
  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create FTS5 virtual table for full-text search
        await customStatement('''
          CREATE VIRTUAL TABLE IF NOT EXISTS items_fts USING fts5(
            name,
            description,
            notes,
            serial_number,
            barcode,
            content=items,
            content_rowid=rowid
          )
        ''');
        // Triggers to keep FTS in sync
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS items_fts_insert AFTER INSERT ON items BEGIN
            INSERT INTO items_fts(rowid, name, description, notes, serial_number, barcode)
            VALUES (new.rowid, new.name, new.description, new.notes, new.serial_number, new.barcode);
          END
        ''');
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS items_fts_update AFTER UPDATE ON items BEGIN
            INSERT INTO items_fts(items_fts, rowid, name, description, notes, serial_number, barcode)
            VALUES ('delete', old.rowid, old.name, old.description, old.notes, old.serial_number, old.barcode);
            INSERT INTO items_fts(rowid, name, description, notes, serial_number, barcode)
            VALUES (new.rowid, new.name, new.description, new.notes, new.serial_number, new.barcode);
          END
        ''');
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS items_fts_delete AFTER DELETE ON items BEGIN
            INSERT INTO items_fts(items_fts, rowid, name, description, notes, serial_number, barcode)
            VALUES ('delete', old.rowid, old.name, old.description, old.notes, old.serial_number, old.barcode);
          END
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Recreate receipts and price_history tables with updated schema.
          await m.deleteTable('price_history');
          await m.deleteTable('receipts');
          await m.createTable(receipts);
          await m.createTable(priceHistoryEntries);
        }
        if (from < 3) {
          await m.createTable(maintenanceLogs);
        }
        if (from < 4) {
          // Add nodeId/hlc to MaintenanceLogs (missing in v3).
          await m.addColumn(maintenanceLogs, maintenanceLogs.nodeId);
          await m.addColumn(maintenanceLogs, maintenanceLogs.hlc);
          // Add soft-delete tombstone column to all 12 tables.
          await m.addColumn(properties, properties.isDeleted);
          await m.addColumn(rooms, rooms.isDeleted);
          await m.addColumn(categories, categories.isDeleted);
          await m.addColumn(items, items.isDeleted);
          await m.addColumn(tags, tags.isDeleted);
          await m.addColumn(itemTags, itemTags.isDeleted);
          await m.addColumn(photos, photos.isDeleted);
          await m.addColumn(receipts, receipts.isDeleted);
          await m.addColumn(priceHistoryEntries, priceHistoryEntries.isDeleted);
          await m.addColumn(policies, policies.isDeleted);
          await m.addColumn(maintenanceLogs, maintenanceLogs.isDeleted);
          await m.addColumn(videoAnalyses, videoAnalyses.isDeleted);
        }
        if (from < 5) {
          await m.createTable(productLookupCache);
        }
        if (from < 6) {
          await m.createTable(storageContainers);
          await m.addColumn(items, items.containerId);
        }
        if (from < 7) {
          await m.createTable(loans);
        }
        if (from < 8) {
          await m.addColumn(items, items.quantity);
          await m.addColumn(items, items.quantityUnit);
          await m.addColumn(items, items.lowStockThreshold);
        }
        if (from < 9) {
          await m.createTable(profiles); // MUST precede addColumn (FK ref)
          await m.addColumn(items, items.creatorProfileId);
          await m.addColumn(items, items.ownerProfileId);
        }
        if (from < 10) {
          await m.createTable(appraisals);
        }
        if (from < 11) {
          // Backfill nullable nodeId/hlc on appraisals so they match every
          // other CRDT-stamped table (NOT NULL DEFAULT ''). Schema columns
          // themselves are regenerated by Drift codegen — this just clears
          // any nulls that v10 may have written before the schema bump.
          await customStatement(
            "UPDATE appraisals SET node_id = '' WHERE node_id IS NULL",
          );
          await customStatement(
            "UPDATE appraisals SET hlc = '' WHERE hlc IS NULL",
          );
        }
      },
    );
  }

  // ── Product lookup cache helpers ─────────────────────────────────────────

  Future<ProductLookupCacheData?> getCachedProduct(String barcode) => (select(
    productLookupCache,
  )..where((t) => t.barcode.equals(barcode))).getSingleOrNull();

  Future<void> cacheProduct(
    String barcode,
    String name, {
    String? description,
    String? brand,
  }) => into(productLookupCache).insertOnConflictUpdate(
    ProductLookupCacheCompanion.insert(
      barcode: barcode,
      name: name,
      description: Value(description),
      brand: Value(brand),
      cachedAt: DateTime.now(),
    ),
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbDir.path, 'still_life.db'));
    return NativeDatabase.createInBackground(file);
  });
}

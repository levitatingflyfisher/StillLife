import 'package:drift/drift.dart';

import '../storage/legacy_photo_files/legacy_photo_files.dart';
import '../storage/photo_bytes.dart';
import 'connection/connection.dart';
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
  AppDatabase(super.e, {Future<Uint8List?> Function(String path)? migrationFileReader})
      : _migrationFileReader = migrationFileReader ?? readLegacyPhotoFile;

  /// Reads a legacy photo file during the v12 backfill. Injectable so the
  /// migration is testable without a real filesystem; the default reads from
  /// disk on native and always returns null on the web (which has no legacy
  /// files to migrate).
  final Future<Uint8List?> Function(String path) _migrationFileReader;

  /// Production constructor — native SQLite file on mobile/desktop, the
  /// sqlite3 WASM build (in a web worker) in the browser. The platform split
  /// lives in `connection/connection.dart`.
  factory AppDatabase.production() {
    return AppDatabase(openConnection());
  }

  /// In-memory constructor for testing.
  factory AppDatabase.memory() {
    return AppDatabase(openMemoryConnection());
  }

  @override
  int get schemaVersion => 15;

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
        await _createFtsTriggers();
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
        if (from < 12) {
          // Photos move into the database as BLOBs so they work identically
          // on native and web (the web has no filesystem). Backfill reads
          // each legacy file from disk; a missing file leaves bytes null but
          // KEEPS the row — never crash a migration over a lost photo.
          await m.addColumn(photos, photos.bytes);
          await m.addColumn(photos, photos.thumbBytes);
          await m.addColumn(receipts, receipts.photoBytes);
          await _backfillPhotoBlobs();
        }
        if (from < 13) {
          // Product identity columns — nullable, so existing rows simply
          // gain nulls and old backups keep importing unchanged.
          await m.addColumn(items, items.brand);
          await m.addColumn(items, items.model);
          await m.addColumn(items, items.asin);
        }
        if (from < 14) {
          // Receipt linkage — nullable, so existing rows gain null and
          // pre-v14 backups keep importing unchanged.
          await m.addColumn(items, items.receiptId);
        }
        if (from < 15) {
          // Money moves from REAL dollars to INTEGER cents so arithmetic is
          // exact. Stored dollars convert via the same decimal
          // half-away-from-zero law as centsFromDollars (the epsilon nudges
          // scaled values a binary hair below a half-cent over the line);
          // NULL stays NULL. Every wire format (backup JSON, CSV, sync)
          // keeps speaking dollars — only storage changes.
          //
          // Migrations here are not transactional, so each table rebuild is
          // guarded by "does the dollar column still exist": a re-entry after
          // a mid-migration crash skips what already converted instead of
          // failing on the renamed column.
          Expression<int> centsOf(String dollarColumn) => CustomExpression(
                'CAST(ROUND($dollarColumn * 100 + '
                '(CASE WHEN $dollarColumn < 0 THEN -1e-9 ELSE 1e-9 END)) '
                'AS INTEGER)',
              );
          Future<bool> stillDollars(String table, String column) async {
            final cols = await customSelect(
              'SELECT name FROM pragma_table_info(?1)',
              variables: [Variable<String>(table)],
            ).get();
            return cols.any((r) => r.read<String>('name') == column);
          }

          if (await stillDollars('items', 'purchase_price')) {
            await m.alterTable(TableMigration(items, columnTransformer: {
              items.purchasePriceCents: centsOf('purchase_price'),
              items.currentValueCents: centsOf('current_value'),
              items.replacementCostCents: centsOf('replacement_cost'),
            }));
            // Rebuilding items dropped its FTS triggers with the old table;
            // recreate them and rebuild the external-content index.
            final hasFts = await customSelect(
              "SELECT name FROM sqlite_master WHERE name = 'items_fts'",
            ).get();
            if (hasFts.isNotEmpty) {
              await _createFtsTriggers();
              await customStatement(
                "INSERT INTO items_fts(items_fts) VALUES('rebuild')",
              );
            }
          }
          if (await stillDollars('receipts', 'total_amount')) {
            await m.alterTable(TableMigration(receipts, columnTransformer: {
              receipts.totalAmountCents: centsOf('total_amount'),
            }));
          }
          if (await stillDollars('price_history_entries', 'price')) {
            await m.alterTable(
              TableMigration(priceHistoryEntries, columnTransformer: {
                priceHistoryEntries.priceCents: centsOf('price'),
              }),
            );
          }
          if (await stillDollars('policies', 'coverage_amount')) {
            await m.alterTable(TableMigration(policies, columnTransformer: {
              policies.coverageAmountCents: centsOf('coverage_amount'),
              policies.deductibleCents: centsOf('deductible'),
              policies.premiumCents: centsOf('premium'),
            }));
          }
          if (await stillDollars('maintenance_logs', 'cost')) {
            await m.alterTable(
              TableMigration(maintenanceLogs, columnTransformer: {
                maintenanceLogs.costCents: centsOf('cost'),
              }),
            );
          }
          if (await stillDollars('appraisals', 'value')) {
            await m.alterTable(TableMigration(appraisals, columnTransformer: {
              appraisals.valueCents: centsOf('value'),
            }));
          }
        }
      },
    );
  }

  /// The FTS sync triggers, shared by onCreate and the v15 items rebuild
  /// (dropping a table drops its triggers, so any migration that rebuilds
  /// `items` must recreate them and rebuild the index).
  Future<void> _createFtsTriggers() async {
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
  }

  /// v12 backfill: pull legacy photo/receipt files into the new BLOB columns.
  ///
  /// Uses raw SQL (not the generated queries) because it runs mid-migration.
  /// Every row is handled independently and best-effort: unreadable or
  /// missing files leave the row in place with null bytes.
  Future<void> _backfillPhotoBlobs() async {
    final photoRows = await customSelect(
      "SELECT id, file_path FROM photos WHERE bytes IS NULL AND file_path != ''",
    ).get();
    for (final row in photoRows) {
      try {
        final bytes = await _migrationFileReader(row.read<String>('file_path'));
        if (bytes == null) continue; // file gone — keep the row as-is
        await customStatement(
          'UPDATE photos SET bytes = ?, thumb_bytes = ? WHERE id = ?',
          [bytes, buildThumbnailBytes(bytes), row.read<String>('id')],
        );
      } catch (_) {
        // Best-effort per row; a corrupt file must not brick the migration.
      }
    }

    final receiptRows = await customSelect(
      'SELECT id, photo_path FROM receipts '
      "WHERE photo_bytes IS NULL AND photo_path != ''",
    ).get();
    for (final row in receiptRows) {
      try {
        final bytes =
            await _migrationFileReader(row.read<String>('photo_path'));
        if (bytes == null) continue;
        await customStatement(
          'UPDATE receipts SET photo_bytes = ? WHERE id = ?',
          [bytes, row.read<String>('id')],
        );
      } catch (_) {
        // Best-effort per row.
      }
    }
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


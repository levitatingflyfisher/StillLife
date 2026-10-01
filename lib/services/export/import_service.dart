import 'dart:convert';

import '../../core/utils/money.dart';

import 'package:crdt/crdt.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../database/database.dart';

class ImportService {
  final AppDatabase _db;

  /// Test-only seam: lets unit tests override the app-documents-directory
  /// resolution without needing to mock `path_provider` platform channels.
  /// Production code always leaves this `null`.
  final Future<String?> Function()? _photoRootResolver;

  /// Wall clock for the future-stamp bound; tests pass a fixed one.
  final DateTime Function() _clock;

  ImportService(
    this._db, {
    Future<String?> Function()? photoRootResolver,
    DateTime Function()? clock,
  }) : _photoRootResolver = photoRootResolver,
       _clock = clock ?? DateTime.now;

  /// How far ahead of this device's clock an incoming row's stamp may be.
  ///
  /// A row stamped further ahead is held back on the sync path (not applied
  /// this time): the peer sends a full snapshot every sync, so the row lands
  /// once local time catches up, and a clock set a year ahead parks its own
  /// rows instead of winning every later race. Ten minutes is the sync
  /// kernel design's MAX_FUTURE_SKEW (§3.2): Willow's bound, which it calls
  /// "more than enough for any clock drift that can be considered non-buggy".
  static const maxFutureSkew = Duration(minutes: 10);

  /// Parses an incoming stamp, or null when it is absent or unreadable. A
  /// stamp that does not parse is no stamp: as a raw string, 'zzz' would sort
  /// after every real HLC and win every race forever.
  static Hlc? _parseStamp(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return Hlc.parse(raw);
    } catch (_) {
      return null;
    }
  }

  /// How many rows in a JSON export carry no usable stamp. An explicit file
  /// import applies them anyway (a pre-stamp file is still importable), so the
  /// UI warns first when this is non-zero. Returns 0 for anything unreadable;
  /// [importFromJson] reports that failure itself.
  static int countUnstampedRows(String jsonString) {
    try {
      final data = json.decode(jsonString);
      if (data is! Map) return 0;
      final content = data['data'];
      if (content is! Map) return 0;
      var n = 0;
      for (final key in _lwwTables.keys) {
        final rows = content[key];
        if (rows is! List) continue;
        for (final row in rows) {
          if (row is Map && _parseStamp(row['hlc']) == null) n++;
        }
      }
      return n;
    } catch (_) {
      return 0;
    }
  }

  /// Resolves the app documents directory, returning `null` in environments
  /// where it is not available (e.g. unit tests without a
  /// `path_provider_platform_interface` mock). When `null`, photo/receipt
  /// path validation is skipped — those environments never write to disk.
  Future<String?> _resolvePhotoRoot() async {
    final override = _photoRootResolver;
    if (override != null) return override();
    try {
      final dir = await getApplicationDocumentsDirectory();
      return p.normalize(dir.path);
    } catch (_) {
      return null;
    }
  }

  /// Returns true if [rawPath] is safe to insert — i.e. it resolves to a
  /// location inside the app's documents directory. Rejects absolute paths
  /// that escape the sandbox, `..` traversal, and symlink-style prefixes.
  bool _isPathSafe(String? rawPath, String? photoRoot) {
    if (rawPath == null || rawPath.isEmpty) return true;
    // If we couldn't resolve a sandbox root (e.g. in tests), skip the check.
    if (photoRoot == null) return true;
    final normalized = p.normalize(rawPath);
    // Only accept paths inside the dedicated media subdirectories. Validating
    // against the whole documents root let a crafted import point a filePath at
    // the database itself (still_life.db lives in the ROOT, not a media dir);
    // a later item delete would then unlink it and wipe the entire database.
    for (final sub in const ['photos', 'thumbnails', 'receipts']) {
      if (p.isWithin(p.join(photoRoot, sub), normalized)) return true;
    }
    return false;
  }

  /// content JSON key → (SQL table, JSON key → SQL key column) for every
  /// table merged by stamped last-writer-wins. Every synced table is here:
  /// appraisals and item tags joined once their local writes were stamped and
  /// tag-link removals became tombstones (before, both were
  /// last-received-wins, and a removed tag came back from any peer).
  static const _lwwTables = <String, (String, Map<String, String>)>{
    'properties': ('properties', _byId),
    'rooms': ('rooms', _byId),
    'categories': ('categories', _byId),
    'items': ('items', _byId),
    'tags': ('tags', _byId),
    'photos': ('photos', _byId),
    'receipts': ('receipts', _byId),
    'loans': ('loans', _byId),
    'policies': ('policies', _byId),
    'maintenanceLogs': ('maintenance_logs', _byId),
    'priceHistory': ('price_history_entries', _byId),
    'storageContainers': ('storage_containers', _byId),
    'profiles': ('profiles', _byId),
    'appraisals': ('appraisals', _byId),
    // A tag link is one row per (item, tag) pair with a stamp and a
    // tombstone: an LWW-element-set, so a remove and a re-add are decided by
    // time. Add-wins would need a unique id per add, which the pair key
    // cannot hold.
    'itemTags': ('item_tags', {'itemId': 'item_id', 'tagId': 'tag_id'}),
  };
  static const _byId = {'id': 'id'};

  /// Returns [content] with every CRDT table's rows filtered to only those that
  /// win last-writer-wins against the current local row (see [_lwwShouldWrite]).
  ///
  /// Also returns how many rows were held back for a later sync: stamped
  /// too far ahead ([maxFutureSkew]), or waiting for a parent that is not
  /// here yet ([_holdBackOrphans]). Rows that simply lost LWW are not
  /// counted; they are older, not waiting.
  Future<(Map<String, dynamic>, int)> _lwwFilter(
      Map<String, dynamic> content) async {
    final out = Map<String, dynamic>.from(content);
    var heldBack = 0;
    for (final entry in _lwwTables.entries) {
      final rows = content[entry.key];
      if (rows is! List) continue;
      final (table, keys) = entry.value;
      final kept = <dynamic>[];
      for (final row in rows) {
        if (row is! Map) {
          kept.add(row);
          continue;
        }
        final key = <String, String>{};
        for (final k in keys.entries) {
          final v = row[k.key];
          if (v is String) key[k.value] = v;
        }
        final hlc = row['hlc'] as String? ?? '';
        if (key.length != keys.length ||
            await _lwwShouldWrite(table, key, hlc)) {
          kept.add(row);
        } else if (_isAhead(hlc)) {
          heldBack++;
        }
      }
      out[entry.key] = kept;
    }
    heldBack += await _holdBackOrphans(out);
    return (out, heldBack);
  }

  /// True when [incomingHlc] is stamped beyond [maxFutureSkew].
  bool _isAhead(String incomingHlc) {
    final stamp = _parseStamp(incomingHlc);
    return stamp != null &&
        stamp.dateTime.isAfter(_clock().toUtc().add(maxFutureSkew));
  }

  /// Parents before children: the order the upsert below writes in.
  static const _parentsFirst = [
    'properties', 'rooms', 'storageContainers', 'categories', 'tags',
    'profiles', 'items', 'loans', 'itemTags', 'photos', 'receipts',
    'priceHistory', 'policies', 'maintenanceLogs', 'appraisals',
  ];

  /// Drops (holds back) every incoming row whose parent is neither stored
  /// locally nor arriving in this changeset. SQLite enforces the foreign
  /// keys, so one such row would otherwise fail the whole sync; this way a
  /// child waits with its held-back parent (or for a parent that has not
  /// arrived yet) and lands on a later sync. Walking parents first makes it
  /// transitive: a held-back room holds back its items and their photos.
  ///
  /// The references come from SQLite itself (PRAGMA foreign_key_list), so
  /// this cannot drift from the schema. A tombstoned local parent counts as
  /// present: the key checks existence, not liveness.
  Future<int> _holdBackOrphans(Map<String, dynamic> out) async {
    var dropped = 0;
    assert(_parentsFirst.toSet().containsAll(_lwwTables.keys));
    final arriving = <String, Set<String>>{}; // SQL table -> kept ids
    for (final jsonKey in _parentsFirst) {
      final (table, _) = _lwwTables[jsonKey]!;
      final rows = out[jsonKey];
      if (rows is! List) continue;
      final refs = await _db.customSelect('PRAGMA foreign_key_list($table)').get();
      final kept = <dynamic>[];
      for (final row in rows) {
        if (row is! Map) {
          kept.add(row);
          continue;
        }
        var parentsPresent = true;
        for (final ref in refs) {
          final parent = ref.read<String>('table');
          final value = row[_camel(ref.read<String>('from'))];
          if (value is! String) continue; // a null reference points nowhere
          if (arriving[parent]?.contains(value) ?? false) continue;
          final to = ref.readNullable<String>('to') ?? 'id';
          final local = await _db.customSelect(
            'SELECT 1 FROM $parent WHERE $to = ? LIMIT 1',
            variables: [Variable<String>(value)],
          ).get();
          if (local.isEmpty) {
            parentsPresent = false;
            break;
          }
        }
        if (!parentsPresent) {
          dropped++;
          continue;
        }
        kept.add(row);
        final id = row['id'];
        if (id is String) (arriving[table] ??= {}).add(id);
      }
      out[jsonKey] = kept;
    }
    return dropped;
  }

  /// `creator_profile_id` -> `creatorProfileId`: SQL column to JSON key.
  static String _camel(String snake) {
    final parts = snake.split('_');
    return parts.first +
        parts.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
  }

  /// True when the incoming record should be applied under HLC last-writer-wins
  /// on the SYNC path (Peckish's `_wins`, operator decision 5):
  /// - a stamp beyond [maxFutureSkew] is held back, even into a hole, or it
  ///   would win every later edit of that row;
  /// - no local row: apply (a row without a stamp can only fill a hole);
  /// - incoming has no usable stamp: keep local, never overwrite;
  /// - local has no usable stamp: apply the stamped row;
  /// - otherwise apply only a strictly greater HLC (strings sort as stamps).
  Future<bool> _lwwShouldWrite(
    String table,
    Map<String, String> key,
    String incomingHlc,
  ) async {
    final stamp = _parseStamp(incomingHlc);
    if (stamp != null &&
        stamp.dateTime.isAfter(_clock().toUtc().add(maxFutureSkew))) {
      return false;
    }
    final where = key.keys.map((c) => '$c = ?').join(' AND ');
    final rows = await _db.customSelect(
      'SELECT hlc FROM $table WHERE $where LIMIT 1',
      variables: [for (final v in key.values) Variable<String>(v)],
    ).get();
    if (rows.isEmpty) return true;
    if (stamp == null) return false;
    // An unreadable LOCAL stamp is no stamp either, or a garbage stamp that
    // once filled a hole would out-sort every real update and freeze the row.
    final localHlc = rows.first.read<String?>('hlc');
    if (_parseStamp(localHlc) == null) return true;
    return incomingHlc.compareTo(localHlc!) > 0;
  }

  /// Import data from a JSON string. Inserts or replaces records.
  /// [lww] enables per-record last-writer-wins by HLC (see [_lwwShouldWrite]):
  /// a row is applied only when there is no local row, or it carries a stamp
  /// strictly newer than the local one; an unstamped row only fills a hole,
  /// and a stamp beyond [maxFutureSkew] waits. Sync merges must pass
  /// `lww: true` so a stale peer can't overwrite a newer local edit or
  /// resurrect a newer tombstone. Backup RESTORE and explicit file import keep
  /// the default (false): they replace local rows wholesale, unstamped ones
  /// included, so the UI warns first ([countUnstampedRows]).
  Future<Result<ImportSummary>> importFromJson(
    String jsonString, {
    bool lww = false,
  }) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final photoRoot = await _resolvePhotoRoot();

      // Validate schema
      if (data['app'] != 'still_life') {
        return const Err(ImportFailure('Not a Still Life backup file'));
      }
      final version = data['version'] as String?;
      if (version == null) {
        return const Err(ImportFailure('Missing version in backup file'));
      }

      final content0 = data['data'] as Map<String, dynamic>? ?? {};

      var propertiesCount = 0;
      var roomsCount = 0;
      var containersCount = 0;
      var categoriesCount = 0;
      var itemsCount = 0;
      var tagsCount = 0;
      var receiptsCount = 0;
      var priceHistoryCount = 0;
      var maintenanceLogsCount = 0;
      var loansCount = 0;
      var profilesCount = 0;
      var appraisalsCount = 0;
      var heldBack = 0;

      await _db.transaction(() async {
        // For a sync merge, drop incoming rows that are not strictly newer than
        // the local row (HLC last-writer-wins). The upsert loop below then only
        // ever writes winning rows, so a stale peer can't clobber newer local
        // edits or flip a newer tombstone back to live.
        final (content, held) =
            lww ? await _lwwFilter(content0) : (content0, 0);
        heldBack = held;
        // Import in dependency order:
        // properties → rooms → storageContainers → categories → tags → items → itemTags → photos → receipts → priceHistory

        // Properties
        final properties = (content['properties'] as List<dynamic>?) ?? [];
        for (final p in properties) {
          final map = p as Map<String, dynamic>;
          await _db
              .into(_db.properties)
              .insertOnConflictUpdate(
                PropertiesCompanion.insert(
                  id: map['id'] as String,
                  name: map['name'] as String,
                  address: Value(map['address'] as String?),
                  type: Value(map['type'] as String? ?? 'Home'),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  modifiedAt: DateTime.parse(map['modifiedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          propertiesCount++;
        }

        // Rooms
        final rooms = (content['rooms'] as List<dynamic>?) ?? [];
        for (final r in rooms) {
          final map = r as Map<String, dynamic>;
          // A room's photoPath is a file that room-delete can unlink, so it must
          // pass the same media-dir guard as photos/receipts (was unchecked).
          final rawRoomPhoto = map['photoPath'] as String?;
          final roomPhoto =
              _isPathSafe(rawRoomPhoto, photoRoot) ? rawRoomPhoto : null;
          await _db
              .into(_db.rooms)
              .insertOnConflictUpdate(
                RoomsCompanion.insert(
                  id: map['id'] as String,
                  propertyId: map['propertyId'] as String,
                  parentId: Value(map['parentId'] as String?),
                  name: map['name'] as String,
                  floor: Value(map['floor'] as String?),
                  sortOrder: Value(map['sortOrder'] as int? ?? 0),
                  photoPath: Value(roomPhoto),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  modifiedAt: DateTime.parse(map['modifiedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          roomsCount++;
        }

        // StorageContainers (after rooms, before items)
        final storageContainersRaw =
            (content['storageContainers'] as List<dynamic>?) ?? [];
        for (final c in storageContainersRaw) {
          final map = c as Map<String, dynamic>;
          await _db
              .into(_db.storageContainers)
              .insertOnConflictUpdate(
                StorageContainersCompanion.insert(
                  id: map['id'] as String,
                  roomId: map['roomId'] as String,
                  name: map['name'] as String,
                  type: Value(map['type'] as String?),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  modifiedAt: DateTime.parse(map['modifiedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          containersCount++;
        }

        // Categories
        final categories = (content['categories'] as List<dynamic>?) ?? [];
        for (final c in categories) {
          final map = c as Map<String, dynamic>;
          await _db
              .into(_db.categories)
              .insertOnConflictUpdate(
                CategoriesCompanion.insert(
                  id: map['id'] as String,
                  name: map['name'] as String,
                  parentId: Value(map['parentId'] as String?),
                  iconCodePoint: Value(map['iconCodePoint'] as int?),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  modifiedAt: DateTime.parse(map['modifiedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          categoriesCount++;
        }

        // Tags
        final tags = (content['tags'] as List<dynamic>?) ?? [];
        for (final t in tags) {
          final map = t as Map<String, dynamic>;
          await _db
              .into(_db.tags)
              .insertOnConflictUpdate(
                TagsCompanion.insert(
                  id: map['id'] as String,
                  name: map['name'] as String,
                  color: Value(map['color'] as int?),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  modifiedAt: DateTime.parse(map['modifiedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          tagsCount++;
        }

        // Profiles (before Items: Items have FK creatorProfileId/ownerProfileId → Profiles)
        // backward-compatible: missing key yields empty list
        final profilesRaw = (content['profiles'] as List<dynamic>?) ?? [];
        for (final p in profilesRaw) {
          final map = p as Map<String, dynamic>;
          await _db.profileDao.upsertProfile(
            ProfilesCompanion(
              id: Value(map['id'] as String),
              name: Value(map['name'] as String),
              colorHex: Value(map['colorHex'] as String? ?? '#6750A4'),
              avatarEmoji: Value(map['avatarEmoji'] as String? ?? '👤'), // not-rendered: an avatar id
              isDefault: Value(map['isDefault'] as bool? ?? false),
              createdAt: Value(DateTime.parse(map['createdAt'] as String)),
              modifiedAt: Value(DateTime.parse(map['modifiedAt'] as String)),
              nodeId: Value(map['nodeId'] as String? ?? ''),
              hlc: Value(map['hlc'] as String? ?? ''),
              isDeleted: Value(map['isDeleted'] as bool? ?? false),
            ),
          );
          profilesCount++;
        }

        // Items
        final items = (content['items'] as List<dynamic>?) ?? [];
        for (final i in items) {
          final map = i as Map<String, dynamic>;
          await _db
              .into(_db.items)
              .insertOnConflictUpdate(
                ItemsCompanion.insert(
                  id: map['id'] as String,
                  name: map['name'] as String,
                  description: Value(map['description'] as String? ?? ''),
                  categoryId: map['categoryId'] as String,
                  roomId: map['roomId'] as String,
                  containerId: Value(map['containerId'] as String?),
                  purchaseDate: Value(
                    map['purchaseDate'] != null
                        ? DateTime.parse(map['purchaseDate'] as String)
                        : null,
                  ),
                  // The wire speaks dollars; storage is integer cents.
                  purchasePriceCents: Value(
                    centsFromDollarsOrNull(
                      (map['purchasePrice'] as num?)?.toDouble(),
                    ),
                  ),
                  currentValueCents: Value(
                    centsFromDollarsOrNull(
                      (map['currentValue'] as num?)?.toDouble(),
                    ),
                  ),
                  replacementCostCents: Value(
                    centsFromDollarsOrNull(
                      (map['replacementCost'] as num?)?.toDouble(),
                    ),
                  ),
                  condition: Value(map['condition'] as String?),
                  serialNumber: Value(map['serialNumber'] as String?),
                  // Absent in pre-v13 backups → null (backward-compatible).
                  brand: Value(map['brand'] as String?),
                  model: Value(map['model'] as String?),
                  asin: Value(map['asin'] as String?),
                  // Absent in pre-v14 backups → null (backward-compatible).
                  receiptId: Value(map['receiptId'] as String?),
                  warrantyExpiration: Value(
                    map['warrantyExpiration'] != null
                        ? DateTime.parse(map['warrantyExpiration'] as String)
                        : null,
                  ),
                  barcode: Value(map['barcode'] as String?),
                  storeUrl: Value(map['storeUrl'] as String?),
                  notes: Value(map['notes'] as String?),
                  isInsured: Value(map['isInsured'] as bool? ?? false),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  modifiedAt: DateTime.parse(map['modifiedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  quantity: Value((map['quantity'] as num?)?.toDouble()),
                  quantityUnit: Value(map['quantityUnit'] as String?),
                  lowStockThreshold: Value(
                    (map['lowStockThreshold'] as num?)?.toDouble(),
                  ),
                  creatorProfileId: Value(map['creatorProfileId'] as String?),
                  ownerProfileId: Value(map['ownerProfileId'] as String?),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          itemsCount++;
        }

        // Loans (after Items: FK loans.itemId → items.id).
        // Backward-compatible: missing key yields empty list.
        final loansRaw = (content['loans'] as List<dynamic>?) ?? [];
        for (final l in loansRaw) {
          final map = l as Map<String, dynamic>;
          await _db
              .into(_db.loans)
              .insertOnConflictUpdate(
                LoansCompanion.insert(
                  id: map['id'] as String,
                  itemId: map['itemId'] as String,
                  borrowerName: map['borrowerName'] as String,
                  expectedReturnDate: Value(
                    map['expectedReturnDate'] != null
                        ? DateTime.parse(map['expectedReturnDate'] as String)
                        : null,
                  ),
                  notes: Value(map['notes'] as String?),
                  returnedAt: Value(
                    map['returnedAt'] != null
                        ? DateTime.parse(map['returnedAt'] as String)
                        : null,
                  ),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  modifiedAt: DateTime.parse(map['modifiedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          loansCount++;
        }

        // ItemTags
        final itemTags = (content['itemTags'] as List<dynamic>?) ?? [];
        for (final it in itemTags) {
          final map = it as Map<String, dynamic>;
          await _db
              .into(_db.itemTags)
              .insertOnConflictUpdate(
                ItemTagsCompanion.insert(
                  itemId: map['itemId'] as String,
                  tagId: map['tagId'] as String,
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                  deletedWithItemAt: Value(
                    map['deletedWithItemAt'] is String
                        ? DateTime.parse(map['deletedWithItemAt'] as String)
                        : null,
                  ),
                ),
              );
        }

        // Photos (metadata only, file paths may not exist on this device)
        final photos = (content['photos'] as List<dynamic>?) ?? [];
        for (final ph in photos) {
          final map = ph as Map<String, dynamic>;
          final rawPath = map['filePath'] as String?;
          if (!_isPathSafe(rawPath, photoRoot)) {
            if (kDebugMode) {
              debugPrint(
                '[ImportService] Skipping photo with unsafe filePath: $rawPath',
              );
            }
            continue;
          }
          await _db
              .into(_db.photos)
              .insertOnConflictUpdate(
                PhotosCompanion.insert(
                  id: map['id'] as String,
                  itemId: map['itemId'] as String,
                  filePath: map['filePath'] as String,
                  isPrimary: Value(map['isPrimary'] as bool? ?? false),
                  source: Value(map['source'] as String? ?? 'camera'),
                  capturedAt: DateTime.parse(map['capturedAt'] as String),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  modifiedAt: DateTime.parse(map['modifiedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
        }

        // Receipts
        final receiptsRaw = (content['receipts'] as List<dynamic>?) ?? [];
        for (final r in receiptsRaw) {
          final map = r as Map<String, dynamic>;
          final rawPath = map['photoPath'] as String?;
          if (!_isPathSafe(rawPath, photoRoot)) {
            if (kDebugMode) {
              debugPrint(
                '[ImportService] Skipping receipt with unsafe photoPath: $rawPath',
              );
            }
            continue;
          }
          await _db
              .into(_db.receipts)
              .insertOnConflictUpdate(
                ReceiptsCompanion.insert(
                  id: map['id'] as String,
                  itemId: Value(map['itemId'] as String?),
                  photoPath: map['photoPath'] as String,
                  storeName: Value(map['storeName'] as String?),
                  purchaseDate: Value(
                    map['purchaseDate'] != null
                        ? DateTime.parse(map['purchaseDate'] as String)
                        : null,
                  ),
                  totalAmountCents: Value(
                    centsFromDollarsOrNull(
                      (map['totalAmount'] as num?)?.toDouble(),
                    ),
                  ),
                  ocrText: Value(map['ocrText'] as String?),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          receiptsCount++;
        }

        // PriceHistory
        final priceHistoryRaw =
            (content['priceHistory'] as List<dynamic>?) ?? [];
        for (final p in priceHistoryRaw) {
          final map = p as Map<String, dynamic>;
          await _db
              .into(_db.priceHistoryEntries)
              .insertOnConflictUpdate(
                PriceHistoryEntriesCompanion.insert(
                  id: map['id'] as String,
                  itemId: map['itemId'] as String,
                  priceCents: centsFromDollars((map['price'] as num).toDouble()),
                  source: map['source'] as String? ?? 'manual',
                  recordedAt: DateTime.parse(map['recordedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          priceHistoryCount++;
        }

        // Policies
        final policies = (content['policies'] as List<dynamic>?) ?? [];
        for (final p in policies) {
          final map = p as Map<String, dynamic>;
          await _db
              .into(_db.policies)
              .insertOnConflictUpdate(
                PoliciesCompanion.insert(
                  id: map['id'] as String,
                  propertyId: map['propertyId'] as String,
                  provider: map['provider'] as String,
                  policyNumber: Value(map['policyNumber'] as String?),
                  coverageAmountCents: Value(
                    centsFromDollarsOrNull(
                      (map['coverageAmount'] as num?)?.toDouble(),
                    ),
                  ),
                  deductibleCents: Value(
                    centsFromDollarsOrNull(
                      (map['deductible'] as num?)?.toDouble(),
                    ),
                  ),
                  premiumCents: Value(
                    centsFromDollarsOrNull(
                      (map['premium'] as num?)?.toDouble(),
                    ),
                  ),
                  expiryDate: Value(
                    map['expiryDate'] != null
                        ? DateTime.parse(map['expiryDate'] as String)
                        : null,
                  ),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  modifiedAt: DateTime.parse(map['modifiedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
        }

        // MaintenanceLogs
        final maintenanceLogs =
            (content['maintenanceLogs'] as List<dynamic>?) ?? [];
        for (final ml in maintenanceLogs) {
          final map = ml as Map<String, dynamic>;
          await _db
              .into(_db.maintenanceLogs)
              .insertOnConflictUpdate(
                MaintenanceLogsCompanion.insert(
                  id: map['id'] as String,
                  itemId: Value(map['itemId'] as String?),
                  propertyId: Value(map['propertyId'] as String?),
                  title: map['title'] as String,
                  description: Value(map['description'] as String?),
                  costCents: Value(
                    centsFromDollarsOrNull((map['cost'] as num?)?.toDouble()),
                  ),
                  performedAt: DateTime.parse(map['performedAt'] as String),
                  nextDueAt: Value(
                    map['nextDueAt'] != null
                        ? DateTime.parse(map['nextDueAt'] as String)
                        : null,
                  ),
                  servicedBy: Value(map['servicedBy'] as String?),
                  createdAt: DateTime.parse(map['createdAt'] as String),
                  modifiedAt: DateTime.parse(map['modifiedAt'] as String),
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          maintenanceLogsCount++;
        }

        // Appraisals (after items: FK items.id)
        final appraisalsRaw = (content['appraisals'] as List<dynamic>?) ?? [];
        for (final a in appraisalsRaw) {
          final map = a as Map<String, dynamic>;
          await _db
              .into(_db.appraisals)
              .insertOnConflictUpdate(
                AppraisalsCompanion.insert(
                  id: map['id'] as String,
                  itemId: map['itemId'] as String,
                  mode: map['mode'] as String,
                  valueCents: centsFromDollars((map['value'] as num).toDouble()),
                  currency: Value(map['currency'] as String? ?? 'USD'),
                  confidence: Value(
                    (map['confidence'] as num?)?.toDouble() ?? 0.5,
                  ),
                  sourceUrls: Value(map['sourceUrls'] as String? ?? '[]'),
                  itemModelKey: map['itemModelKey'] as String,
                  countryCode: Value(map['countryCode'] as String? ?? 'US'),
                  queriedAt: map['queriedAt'] as int,
                  expiresAt: map['expiresAt'] as int,
                  nodeId: Value(map['nodeId'] as String? ?? ''),
                  hlc: Value(map['hlc'] as String? ?? ''),
                  isDeleted: Value(map['isDeleted'] as bool? ?? false),
                ),
              );
          appraisalsCount++;
        }
      });

      return Success(
        ImportSummary(
          properties: propertiesCount,
          rooms: roomsCount,
          containers: containersCount,
          categories: categoriesCount,
          items: itemsCount,
          tags: tagsCount,
          receipts: receiptsCount,
          priceHistory: priceHistoryCount,
          maintenanceLogs: maintenanceLogsCount,
          loans: loansCount,
          profiles: profilesCount,
          appraisals: appraisalsCount,
          heldBack: heldBack,
        ),
      );
    } on FormatException {
      return const Err(ImportFailure('Invalid JSON format'));
    } catch (e) {
      return Err(ImportFailure('Import failed: $e'));
    }
  }
}

class ImportSummary {
  final int properties;
  final int rooms;
  final int containers;
  final int categories;
  final int items;
  final int tags;
  final int receipts;
  final int priceHistory;
  final int maintenanceLogs;
  final int loans;
  final int profiles;
  final int appraisals;

  /// Rows a sync held back for a later one (see `_lwwFilter`); not counted
  /// in [totalRecords].
  final int heldBack;

  const ImportSummary({
    this.properties = 0,
    this.rooms = 0,
    this.containers = 0,
    this.categories = 0,
    this.items = 0,
    this.tags = 0,
    this.receipts = 0,
    this.priceHistory = 0,
    this.maintenanceLogs = 0,
    this.loans = 0,
    this.profiles = 0,
    this.appraisals = 0,
    this.heldBack = 0,
  });

  int get totalRecords =>
      properties +
      rooms +
      containers +
      categories +
      items +
      tags +
      receipts +
      priceHistory +
      maintenanceLogs +
      loans +
      profiles +
      appraisals;
}

import 'dart:convert';

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

  ImportService(this._db, {Future<String?> Function()? photoRootResolver})
    : _photoRootResolver = photoRootResolver;

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
    if (p.equals(photoRoot, normalized)) return true;
    return p.isWithin(photoRoot, normalized);
  }

  /// Import data from a JSON string. Inserts or replaces records.
  Future<Result<ImportSummary>> importFromJson(String jsonString) async {
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

      final content = data['data'] as Map<String, dynamic>? ?? {};

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

      await _db.transaction(() async {
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
                  photoPath: Value(map['photoPath'] as String?),
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
              avatarEmoji: Value(map['avatarEmoji'] as String? ?? '👤'),
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
                  purchasePrice: Value(
                    (map['purchasePrice'] as num?)?.toDouble(),
                  ),
                  currentValue: Value(
                    (map['currentValue'] as num?)?.toDouble(),
                  ),
                  replacementCost: Value(
                    (map['replacementCost'] as num?)?.toDouble(),
                  ),
                  condition: Value(map['condition'] as String?),
                  serialNumber: Value(map['serialNumber'] as String?),
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
                  totalAmount: Value((map['totalAmount'] as num?)?.toDouble()),
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
                  price: (map['price'] as num).toDouble(),
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
                  coverageAmount: Value(
                    (map['coverageAmount'] as num?)?.toDouble(),
                  ),
                  deductible: Value((map['deductible'] as num?)?.toDouble()),
                  premium: Value((map['premium'] as num?)?.toDouble()),
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
                  cost: Value((map['cost'] as num?)?.toDouble()),
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
                  value: (map['value'] as num).toDouble(),
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

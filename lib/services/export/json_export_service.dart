import 'dart:convert';

import '../../core/utils/money.dart';
import '../database/database.dart';

class JsonExportService {
  final AppDatabase _db;

  /// The int schema version stamped into the envelope (v2 retention key,
  /// additive next to the legacy string 'version'). Bump when the payload
  /// shape changes incompatibly; StillLifeBackupSerializer gates restores
  /// on it via BackupEnvelope.unwrap.
  static const int currentSchemaVersion = 1;

  JsonExportService(this._db);

  /// Export the entire database as a JSON string.
  ///
  /// All table reads run inside a single read transaction so the snapshot is a
  /// consistent point-in-time view. Without it, a concurrent LAN-sync import
  /// (itself a `_db.transaction`) committing between two of these selects could
  /// land a new item's photo row in the export while its parent item — read
  /// earlier — is absent, producing a torn backup no single DB state ever held.
  Future<String> exportToJson() async {
    final rows = await _db.transaction(() async {
      return (
        properties: await _db.select(_db.properties).get(),
        rooms: await _db.select(_db.rooms).get(),
        containers: await _db.select(_db.storageContainers).get(),
        categories: await _db.select(_db.categories).get(),
        items: await _db.select(_db.items).get(),
        tags: await _db.select(_db.tags).get(),
        itemTags: await _db.select(_db.itemTags).get(),
        photos: await _db.select(_db.photos).get(),
        receipts: await _db.select(_db.receipts).get(),
        priceHistory: await _db.select(_db.priceHistoryEntries).get(),
        policies: await _db.select(_db.policies).get(),
        maintenanceLogs: await _db.select(_db.maintenanceLogs).get(),
        loans: await _db.select(_db.loans).get(),
        profiles: await _db.select(_db.profiles).get(),
        appraisals: await _db.select(_db.appraisals).get(),
      );
    });
    final properties = rows.properties;
    final rooms = rows.rooms;
    final containers = rows.containers;
    final categories = rows.categories;
    final items = rows.items;
    final tags = rows.tags;
    final itemTags = rows.itemTags;
    final photos = rows.photos;
    final receipts = rows.receipts;
    final priceHistory = rows.priceHistory;
    final policies = rows.policies;
    final maintenanceLogs = rows.maintenanceLogs;
    final loansList = rows.loans;
    final profilesList = rows.profiles;
    final appraisalsList = rows.appraisals;

    final data = {
      // Legacy keys FIRST and unchanged: the shipped app gates restore on
      // app == 'still_life' + the string major of 'version', and old readers
      // ignore unknown keys — so the two v2 keys below are strictly additive
      // (wire-compat law: new backups must restore on old installs).
      'version': '1.0',
      'app': 'still_life',
      'exportedAt': DateTime.now().toIso8601String(),
      // v2 retention keys (BACKUP_RETENTION_SPEC §2.F): the UTC stamp feeds
      // preview/staleness copy; the int schemaVersion feeds
      // BackupEnvelope.unwrap's future-schema gate.
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'schemaVersion': currentSchemaVersion,
      'data': {
        'properties': properties.map(_propertyToMap).toList(),
        'rooms': rooms.map(_roomToMap).toList(),
        'storageContainers': containers.map(_containerToMap).toList(),
        'categories': categories.map(_categoryToMap).toList(),
        'items': items.map(_itemToMap).toList(),
        'tags': tags.map(_tagToMap).toList(),
        'itemTags': itemTags.map(_itemTagToMap).toList(),
        'photos': photos.map(_photoToMap).toList(),
        'receipts': receipts.map(_receiptToMap).toList(),
        'priceHistory': priceHistory.map(_priceHistoryToMap).toList(),
        'policies': policies.map(_policyToMap).toList(),
        'maintenanceLogs': maintenanceLogs.map(_maintenanceLogToMap).toList(),
        'loans': loansList.map(_loanToMap).toList(),
        'profiles': profilesList.map(_profileToMap).toList(),
        'appraisals': appraisalsList.map(_appraisalToMap).toList(),
      },
      'photosIncluded': false,
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Map<String, dynamic> _propertyToMap(Property p) => {
    'id': p.id,
    'name': p.name,
    'address': p.address,
    'type': p.type,
    'createdAt': p.createdAt.toIso8601String(),
    'modifiedAt': p.modifiedAt.toIso8601String(),
    'nodeId': p.nodeId,
    'hlc': p.hlc,
    'isDeleted': p.isDeleted,
  };

  Map<String, dynamic> _roomToMap(Room r) => {
    'id': r.id,
    'propertyId': r.propertyId,
    'parentId': r.parentId,
    'name': r.name,
    'floor': r.floor,
    'sortOrder': r.sortOrder,
    'photoPath': r.photoPath,
    'createdAt': r.createdAt.toIso8601String(),
    'modifiedAt': r.modifiedAt.toIso8601String(),
    'nodeId': r.nodeId,
    'hlc': r.hlc,
    'isDeleted': r.isDeleted,
  };

  Map<String, dynamic> _categoryToMap(Category c) => {
    'id': c.id,
    'name': c.name,
    'parentId': c.parentId,
    'iconCodePoint': c.iconCodePoint,
    'createdAt': c.createdAt.toIso8601String(),
    'modifiedAt': c.modifiedAt.toIso8601String(),
    'nodeId': c.nodeId,
    'hlc': c.hlc,
    'isDeleted': c.isDeleted,
  };

  Map<String, dynamic> _containerToMap(StorageContainer c) => {
    'id': c.id,
    'roomId': c.roomId,
    'name': c.name,
    'type': c.type,
    'createdAt': c.createdAt.toIso8601String(),
    'modifiedAt': c.modifiedAt.toIso8601String(),
    'nodeId': c.nodeId,
    'hlc': c.hlc,
    'isDeleted': c.isDeleted,
  };

  Map<String, dynamic> _itemToMap(Item i) => {
    'id': i.id,
    'name': i.name,
    'description': i.description,
    'categoryId': i.categoryId,
    'roomId': i.roomId,
    'containerId': i.containerId,
    'purchaseDate': i.purchaseDate?.toIso8601String(),
    // Wire keys and units are frozen: dollars, as every released backup
    // and sync peer speaks. Storage is cents; convert at this boundary.
    'purchasePrice': dollarsFromCentsOrNull(i.purchasePriceCents),
    'currentValue': dollarsFromCentsOrNull(i.currentValueCents),
    'replacementCost': dollarsFromCentsOrNull(i.replacementCostCents),
    'condition': i.condition,
    'serialNumber': i.serialNumber,
    'warrantyExpiration': i.warrantyExpiration?.toIso8601String(),
    'brand': i.brand,
    'model': i.model,
    'asin': i.asin,
    'receiptId': i.receiptId,
    'barcode': i.barcode,
    'storeUrl': i.storeUrl,
    'notes': i.notes,
    'isInsured': i.isInsured,
    'createdAt': i.createdAt.toIso8601String(),
    'modifiedAt': i.modifiedAt.toIso8601String(),
    'nodeId': i.nodeId,
    'hlc': i.hlc,
    'quantity': i.quantity,
    'quantityUnit': i.quantityUnit,
    'lowStockThreshold': i.lowStockThreshold,
    'creatorProfileId': i.creatorProfileId,
    'ownerProfileId': i.ownerProfileId,
    'isDeleted': i.isDeleted,
  };

  Map<String, dynamic> _tagToMap(Tag t) => {
    'id': t.id,
    'name': t.name,
    'color': t.color,
    'createdAt': t.createdAt.toIso8601String(),
    'modifiedAt': t.modifiedAt.toIso8601String(),
    'nodeId': t.nodeId,
    'hlc': t.hlc,
    'isDeleted': t.isDeleted,
  };

  Map<String, dynamic> _itemTagToMap(ItemTag it) => {
    'itemId': it.itemId,
    'tagId': it.tagId,
    'createdAt': it.createdAt.toIso8601String(),
    'nodeId': it.nodeId,
    'hlc': it.hlc,
    'isDeleted': it.isDeleted,
  };

  Map<String, dynamic> _photoToMap(Photo p) => {
    'id': p.id,
    'itemId': p.itemId,
    'filePath': p.filePath,
    'isPrimary': p.isPrimary,
    'source': p.source,
    'capturedAt': p.capturedAt.toIso8601String(),
    'createdAt': p.createdAt.toIso8601String(),
    'modifiedAt': p.modifiedAt.toIso8601String(),
    'nodeId': p.nodeId,
    'hlc': p.hlc,
    'isDeleted': p.isDeleted,
  };

  Map<String, dynamic> _receiptToMap(Receipt r) => {
    'id': r.id,
    'itemId': r.itemId,
    'photoPath': r.photoPath,
    'storeName': r.storeName,
    'purchaseDate': r.purchaseDate?.toIso8601String(),
    'totalAmount': dollarsFromCentsOrNull(r.totalAmountCents),
    'ocrText': r.ocrText,
    'createdAt': r.createdAt.toIso8601String(),
    'nodeId': r.nodeId,
    'hlc': r.hlc,
    'isDeleted': r.isDeleted,
  };

  Map<String, dynamic> _priceHistoryToMap(PriceHistoryEntry p) => {
    'id': p.id,
    'itemId': p.itemId,
    'price': dollarsFromCents(p.priceCents),
    'source': p.source,
    'recordedAt': p.recordedAt.toIso8601String(),
    'nodeId': p.nodeId,
    'hlc': p.hlc,
    'isDeleted': p.isDeleted,
  };

  Map<String, dynamic> _policyToMap(Policy p) => {
    'id': p.id,
    'propertyId': p.propertyId,
    'provider': p.provider,
    'policyNumber': p.policyNumber,
    'coverageAmount': dollarsFromCentsOrNull(p.coverageAmountCents),
    'deductible': dollarsFromCentsOrNull(p.deductibleCents),
    'premium': dollarsFromCentsOrNull(p.premiumCents),
    'expiryDate': p.expiryDate?.toIso8601String(),
    'createdAt': p.createdAt.toIso8601String(),
    'modifiedAt': p.modifiedAt.toIso8601String(),
    'nodeId': p.nodeId,
    'hlc': p.hlc,
    'isDeleted': p.isDeleted,
  };

  Map<String, dynamic> _maintenanceLogToMap(MaintenanceLog m) => {
    'id': m.id,
    'itemId': m.itemId,
    'propertyId': m.propertyId,
    'title': m.title,
    'description': m.description,
    'cost': dollarsFromCentsOrNull(m.costCents),
    'performedAt': m.performedAt.toIso8601String(),
    'nextDueAt': m.nextDueAt?.toIso8601String(),
    'servicedBy': m.servicedBy,
    'createdAt': m.createdAt.toIso8601String(),
    'modifiedAt': m.modifiedAt.toIso8601String(),
    'nodeId': m.nodeId,
    'hlc': m.hlc,
    'isDeleted': m.isDeleted,
  };

  Map<String, dynamic> _loanToMap(Loan l) => {
    'id': l.id,
    'itemId': l.itemId,
    'borrowerName': l.borrowerName,
    'expectedReturnDate': l.expectedReturnDate?.toIso8601String(),
    'notes': l.notes,
    'returnedAt': l.returnedAt?.toIso8601String(),
    'createdAt': l.createdAt.toIso8601String(),
    'modifiedAt': l.modifiedAt.toIso8601String(),
    'nodeId': l.nodeId,
    'hlc': l.hlc,
    'isDeleted': l.isDeleted,
  };

  Map<String, dynamic> _profileToMap(Profile p) => {
    'id': p.id,
    'name': p.name,
    'colorHex': p.colorHex,
    'avatarEmoji': p.avatarEmoji,
    'isDefault': p.isDefault,
    'createdAt': p.createdAt.toIso8601String(),
    'modifiedAt': p.modifiedAt.toIso8601String(),
    'nodeId': p.nodeId,
    'hlc': p.hlc,
    'isDeleted': p.isDeleted,
  };

  Map<String, dynamic> _appraisalToMap(Appraisal a) => {
    'id': a.id,
    'itemId': a.itemId,
    'mode': a.mode,
    'value': dollarsFromCents(a.valueCents),
    'currency': a.currency,
    'confidence': a.confidence,
    'sourceUrls': a.sourceUrls,
    'itemModelKey': a.itemModelKey,
    'countryCode': a.countryCode,
    'queriedAt': a.queriedAt,
    'expiresAt': a.expiresAt,
    'nodeId': a.nodeId,
    'hlc': a.hlc,
    'isDeleted': a.isDeleted,
  };
}

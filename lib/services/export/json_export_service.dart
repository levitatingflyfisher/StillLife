import 'dart:convert';

import '../database/database.dart';

class JsonExportService {
  final AppDatabase _db;

  JsonExportService(this._db);

  /// Export the entire database as a JSON string.
  Future<String> exportToJson() async {
    final properties = await _db.select(_db.properties).get();
    final rooms = await _db.select(_db.rooms).get();
    final containers = await _db.select(_db.storageContainers).get();
    final categories = await _db.select(_db.categories).get();
    final items = await _db.select(_db.items).get();
    final tags = await _db.select(_db.tags).get();
    final itemTags = await _db.select(_db.itemTags).get();
    final photos = await _db.select(_db.photos).get();
    final receipts = await _db.select(_db.receipts).get();
    final priceHistory = await _db.select(_db.priceHistoryEntries).get();
    final policies = await _db.select(_db.policies).get();
    final maintenanceLogs = await _db.select(_db.maintenanceLogs).get();
    final loansList = await _db.select(_db.loans).get();
    final profilesList = await _db.select(_db.profiles).get();
    final appraisalsList = await _db.select(_db.appraisals).get();

    final data = {
      'version': '1.0',
      'app': 'still_life',
      'exportedAt': DateTime.now().toIso8601String(),
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
    'purchasePrice': i.purchasePrice,
    'currentValue': i.currentValue,
    'replacementCost': i.replacementCost,
    'condition': i.condition,
    'serialNumber': i.serialNumber,
    'warrantyExpiration': i.warrantyExpiration?.toIso8601String(),
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
    'totalAmount': r.totalAmount,
    'ocrText': r.ocrText,
    'createdAt': r.createdAt.toIso8601String(),
    'nodeId': r.nodeId,
    'hlc': r.hlc,
    'isDeleted': r.isDeleted,
  };

  Map<String, dynamic> _priceHistoryToMap(PriceHistoryEntry p) => {
    'id': p.id,
    'itemId': p.itemId,
    'price': p.price,
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
    'coverageAmount': p.coverageAmount,
    'deductible': p.deductible,
    'premium': p.premium,
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
    'cost': m.cost,
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
    'value': a.value,
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

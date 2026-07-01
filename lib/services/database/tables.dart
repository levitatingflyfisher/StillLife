import 'package:drift/drift.dart';

/// Properties table — top-level locations (homes, apartments, etc.)
class Properties extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get address => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('Home'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Rooms table — belongs to a property, supports hierarchy via parentId.
class Rooms extends Table {
  TextColumn get id => text()();
  TextColumn get propertyId => text().references(Properties, #id)();
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get floor => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Categories table — item categorization with optional hierarchy.
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get parentId => text().nullable()();
  IntColumn get iconCodePoint => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Items table — the core inventory item.
class Items extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 500)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get roomId => text().references(Rooms, #id)();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  // Money is integer cents (v15): exact arithmetic, no float drift.
  IntColumn get purchasePriceCents => integer().nullable()();
  IntColumn get currentValueCents => integer().nullable()();
  IntColumn get replacementCostCents => integer().nullable()();
  TextColumn get condition => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  DateTimeColumn get warrantyExpiration => dateTime().nullable()();
  TextColumn get containerId =>
      text().nullable()(); // FK to StorageContainers.id
  TextColumn get barcode => text().nullable()();
  TextColumn get storeUrl => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isInsured => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Quantities & consumables (v8)
  RealColumn get quantity => real().nullable()();
  TextColumn get quantityUnit => text().nullable()();
  RealColumn get lowStockThreshold => real().nullable()();

  // Family sharing attribution (v9)
  TextColumn get creatorProfileId =>
      text().nullable().references(Profiles, #id)();
  TextColumn get ownerProfileId =>
      text().nullable().references(Profiles, #id)();

  // Product identity (v13) — real columns so AI suggestions, barcode
  // lookups, and marketplace imports stop smuggling identity into
  // name/notes. `asin` has no form field; it is set programmatically
  // (e.g. Amazon order imports).
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get asin => text().nullable()();

  // Receipt linkage (v14) — points at Receipts.id. A plain column, not a
  // `references()`, because Receipts.itemId already references Items and a
  // declared cycle would break table-creation ordering. One receipt links
  // many items (a multi-item import), so the link lives here and
  // Receipts.itemId stays null for those rows.
  TextColumn get receiptId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// FTS5 virtual table (items_fts) is created via custom SQL in database.dart migration.

/// Tags table — user-defined labels.
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get color => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Item-Tag junction table.
class ItemTags extends Table {
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get tagId => text().references(Tags, #id)();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {itemId, tagId};
}

/// Photos table — item photos.
class Photos extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(Items, #id)();

  /// Legacy pre-v12 location of the photo on disk. New photos store '' here;
  /// the bytes live in [bytes]. Kept so old JSON exports keep importing.
  TextColumn get filePath => text()();

  /// Full-size photo bytes (v12+). Null only for legacy rows whose backing
  /// file had already vanished before the v12 backfill.
  BlobColumn get bytes => blob().nullable()();

  /// JPEG thumbnail (~200px wide) derived from [bytes]; best-effort.
  BlobColumn get thumbBytes => blob().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().withDefault(
    const Constant('camera'),
  )(); // camera, gallery, videoFrame
  DateTimeColumn get capturedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Receipts table — purchase proof linked to items.
class Receipts extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().nullable().references(Items, #id)();

  /// Legacy pre-v12 location of the receipt photo on disk. New receipts
  /// store '' here; the bytes live in [photoBytes].
  TextColumn get photoPath => text()();

  /// Receipt photo bytes (v12+). Null only for legacy rows whose backing
  /// file had already vanished before the v12 backfill.
  BlobColumn get photoBytes => blob().nullable()();
  TextColumn get storeName => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  IntColumn get totalAmountCents => integer().nullable()();
  TextColumn get ocrText => text().nullable()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Price history — tracks prices over time.
class PriceHistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(Items, #id)();
  IntColumn get priceCents => integer()();
  TextColumn get source =>
      text()(); // "amazon", "manual", "receipt", "llm_estimate"
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Insurance policies linked to properties.
class Policies extends Table {
  TextColumn get id => text()();
  TextColumn get propertyId => text().references(Properties, #id)();
  TextColumn get provider => text()();
  TextColumn get policyNumber => text().nullable()();
  IntColumn get coverageAmountCents => integer().nullable()();
  IntColumn get deductibleCents => integer().nullable()();
  IntColumn get premiumCents => integer().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Maintenance logs — tracks servicing/repairs for appliances and home systems.
class MaintenanceLogs extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().nullable().references(Items, #id)();
  TextColumn get propertyId => text().nullable().references(Properties, #id)();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get description => text().nullable()();
  IntColumn get costCents => integer().nullable()();
  DateTimeColumn get performedAt => dateTime()();
  DateTimeColumn get nextDueAt => dateTime().nullable()();
  TextColumn get servicedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Storage containers — shelves, boxes, drawers, cabinets within a room.
class StorageContainers extends Table {
  TextColumn get id => text()();
  TextColumn get roomId => text().references(Rooms, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get type =>
      text().nullable()(); // shelf, box, drawer, cabinet, etc.
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cache for barcode → product name lookups (avoids repeat network calls).
class ProductLookupCache extends Table {
  TextColumn get barcode => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get brand => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {barcode};
}

/// Loans table — tracks items lent to borrowers.
class Loans extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get borrowerName => text()();
  DateTimeColumn get expectedReturnDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get returnedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Video analyses — tracks video processing sessions.
class VideoAnalyses extends Table {
  TextColumn get id => text()();
  TextColumn get videoPath => text()();
  TextColumn get roomId => text().nullable()();
  TextColumn get status =>
      text()(); // processing, completed, failed, no_ai
  TextColumn get providerTier => text().nullable()();
  IntColumn get frameCount => integer().withDefault(const Constant(0))();
  IntColumn get itemsDetected => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Household profiles — attribution labels, not access gates.
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get colorHex => text().withDefault(const Constant('#6750A4'))();
  TextColumn get avatarEmoji => text().withDefault(const Constant('👤'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Appraisals table (v10) — per-item market-value estimates from the
/// Appraiser feature. Three modes: resale / replace_new / replace_equivalent.
/// Cached by `(itemModelKey, mode, countryCode)` for cross-item reuse.
class Appraisals extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get mode =>
      text()(); // 'resale' | 'replace_new' | 'replace_equivalent'
  IntColumn get valueCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  RealColumn get confidence => real().withDefault(const Constant(0.5))();
  TextColumn get sourceUrls =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get itemModelKey => text()();
  TextColumn get countryCode => text().withDefault(const Constant('US'))();
  IntColumn get queriedAt => integer()();
  IntColumn get expiresAt => integer()();
  TextColumn get nodeId => text().withDefault(const Constant(''))();
  TextColumn get hlc => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

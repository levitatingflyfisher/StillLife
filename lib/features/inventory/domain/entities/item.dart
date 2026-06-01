import 'package:equatable/equatable.dart';

enum ItemCondition {
  newItem('New'),
  likeNew('Like New'),
  good('Good'),
  fair('Fair'),
  poor('Poor');

  final String label;
  const ItemCondition(this.label);

  static ItemCondition? fromString(String? value) {
    if (value == null) return null;
    return ItemCondition.values.where((e) => e.label == value).firstOrNull;
  }
}

class Item extends Equatable {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String roomId;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final double? replacementCost;
  final ItemCondition? condition;
  final String? serialNumber;
  final DateTime? warrantyExpiration;
  final String? barcode;
  final String? storeUrl;
  final String? notes;
  final bool isInsured;
  final String? containerId;
  // Family sharing attribution (v9)
  final String? creatorProfileId;
  final String? ownerProfileId;
  // Quantities & consumables (v8)
  final double? quantity;
  final String? quantityUnit;
  final double? lowStockThreshold;
  final DateTime createdAt;
  final DateTime modifiedAt;

  // Joined fields (not stored on item table directly)
  final String? categoryName;
  final String? roomName;
  final String? containerName;
  final List<String> photoIds;
  final List<String> tagIds;
  final bool
  isOnLoan; // display-only badge field; NOT in props (same as categoryName etc.)

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.roomId,
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.replacementCost,
    this.condition,
    this.serialNumber,
    this.warrantyExpiration,
    this.barcode,
    this.storeUrl,
    this.notes,
    this.isInsured = false,
    this.containerId,
    this.creatorProfileId,
    this.ownerProfileId,
    this.quantity,
    this.quantityUnit,
    this.lowStockThreshold,
    required this.createdAt,
    required this.modifiedAt,
    this.categoryName,
    this.roomName,
    this.containerName,
    this.photoIds = const [],
    this.tagIds = const [],
    this.isOnLoan = false,
  });

  Item copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? roomId,
    DateTime? Function()? purchaseDate,
    double? Function()? purchasePrice,
    double? Function()? currentValue,
    double? Function()? replacementCost,
    ItemCondition? Function()? condition,
    String? Function()? serialNumber,
    DateTime? Function()? warrantyExpiration,
    String? Function()? barcode,
    String? Function()? storeUrl,
    String? Function()? notes,
    bool? isInsured,
    String? Function()? containerId,
    String? Function()? creatorProfileId,
    String? Function()? ownerProfileId,
    double? Function()? quantity,
    String? Function()? quantityUnit,
    double? Function()? lowStockThreshold,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? categoryName,
    String? roomName,
    String? containerName,
    List<String>? photoIds,
    List<String>? tagIds,
    bool? isOnLoan,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      roomId: roomId ?? this.roomId,
      purchaseDate: purchaseDate != null ? purchaseDate() : this.purchaseDate,
      purchasePrice: purchasePrice != null
          ? purchasePrice()
          : this.purchasePrice,
      currentValue: currentValue != null ? currentValue() : this.currentValue,
      replacementCost: replacementCost != null
          ? replacementCost()
          : this.replacementCost,
      condition: condition != null ? condition() : this.condition,
      serialNumber: serialNumber != null ? serialNumber() : this.serialNumber,
      warrantyExpiration: warrantyExpiration != null
          ? warrantyExpiration()
          : this.warrantyExpiration,
      barcode: barcode != null ? barcode() : this.barcode,
      storeUrl: storeUrl != null ? storeUrl() : this.storeUrl,
      notes: notes != null ? notes() : this.notes,
      isInsured: isInsured ?? this.isInsured,
      containerId: containerId != null ? containerId() : this.containerId,
      creatorProfileId: creatorProfileId != null
          ? creatorProfileId()
          : this.creatorProfileId,
      ownerProfileId: ownerProfileId != null
          ? ownerProfileId()
          : this.ownerProfileId,
      quantity: quantity != null ? quantity() : this.quantity,
      quantityUnit: quantityUnit != null ? quantityUnit() : this.quantityUnit,
      lowStockThreshold: lowStockThreshold != null
          ? lowStockThreshold()
          : this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      categoryName: categoryName ?? this.categoryName,
      roomName: roomName ?? this.roomName,
      containerName: containerName ?? this.containerName,
      photoIds: photoIds ?? this.photoIds,
      tagIds: tagIds ?? this.tagIds,
      isOnLoan: isOnLoan ?? this.isOnLoan,
    );
  }

  /// True when quantity is set AND at or below the low-stock threshold.
  bool get isLowStock =>
      quantity != null &&
      lowStockThreshold != null &&
      quantity! <= lowStockThreshold!;

  /// True when quantity tracking is enabled for this item.
  bool get isConsumable => quantity != null;

  /// Calculate depreciated value based on purchase price and age.
  /// Uses straight-line depreciation with a 10% residual value.
  static double? calculateDepreciatedValue({
    required double? purchasePrice,
    required DateTime? purchaseDate,
    required int usefulLifeYears,
    DateTime? asOf,
  }) {
    if (purchasePrice == null || purchaseDate == null) return null;

    final now = asOf ?? DateTime.now();
    final ageYears = now.difference(purchaseDate).inDays / 365.25;

    if (ageYears <= 0) return purchasePrice;
    if (ageYears >= usefulLifeYears) return purchasePrice * 0.10;

    final residualValue = purchasePrice * 0.10;
    final depreciableAmount = purchasePrice - residualValue;
    final depreciation = (depreciableAmount / usefulLifeYears) * ageYears;

    return purchasePrice - depreciation;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    categoryId,
    roomId,
    purchaseDate,
    purchasePrice,
    currentValue,
    replacementCost,
    condition,
    serialNumber,
    warrantyExpiration,
    barcode,
    storeUrl,
    notes,
    isInsured,
    createdAt,
    modifiedAt,
    quantity,
    quantityUnit,
    lowStockThreshold,
    creatorProfileId,
    ownerProfileId,
  ];
}

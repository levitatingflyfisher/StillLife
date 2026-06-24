import 'package:equatable/equatable.dart';

/// A parsed line item from a receipt.
class ReceiptLineItem extends Equatable {
  final String description;
  final double? price;
  final int? quantity;

  const ReceiptLineItem({required this.description, this.price, this.quantity});

  @override
  List<Object?> get props => [description, price, quantity];
}

/// A scanned receipt linked to an inventory item.
class Receipt extends Equatable {
  final String id;
  final String? itemId;
  final String photoPath;
  final String? storeName;
  final DateTime? purchaseDate;
  final double? totalAmount;
  final String? ocrText;
  final List<ReceiptLineItem> lineItems;
  final DateTime createdAt;

  const Receipt({
    required this.id,
    this.itemId,
    required this.photoPath,
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    this.ocrText,
    this.lineItems = const [],
    required this.createdAt,
  });

  Receipt copyWith({
    String? id,
    String? itemId,
    String? photoPath,
    String? storeName,
    DateTime? purchaseDate,
    double? totalAmount,
    String? ocrText,
    List<ReceiptLineItem>? lineItems,
    DateTime? createdAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      photoPath: photoPath ?? this.photoPath,
      storeName: storeName ?? this.storeName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      ocrText: ocrText ?? this.ocrText,
      lineItems: lineItems ?? this.lineItems,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id];
}

/// A single price history entry for an item.
class PriceHistoryEntry extends Equatable {
  final String id;
  final String itemId;
  final double price;
  final String source; // "amazon", "manual", "receipt", "llm_estimate"
  final DateTime recordedAt;

  const PriceHistoryEntry({
    required this.id,
    required this.itemId,
    required this.price,
    required this.source,
    required this.recordedAt,
  });

  @override
  List<Object?> get props => [id];
}

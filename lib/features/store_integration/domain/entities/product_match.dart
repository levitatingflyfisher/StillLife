import 'package:equatable/equatable.dart';

/// A product match from an external data source (Amazon, UPC DB, etc.).
class ProductMatch extends Equatable {
  final String source; // "amazon", "upc_itemdb", "open_food_facts", "manual"
  final String productName;
  final String? brand;
  final String? model;
  final String? imageUrl;
  final double? currentPrice;
  final double? usedPrice;
  final String? productUrl;
  final String? upc;
  final double matchConfidence;

  const ProductMatch({
    required this.source,
    required this.productName,
    this.brand,
    this.model,
    this.imageUrl,
    this.currentPrice,
    this.usedPrice,
    this.productUrl,
    this.upc,
    this.matchConfidence = 0.0,
  });

  /// Human-readable display name combining brand + product name.
  String get displayName {
    if (brand != null && brand!.isNotEmpty) {
      return '$brand $productName';
    }
    return productName;
  }

  ProductMatch copyWith({
    String? source,
    String? productName,
    String? brand,
    String? model,
    String? imageUrl,
    double? currentPrice,
    double? usedPrice,
    String? productUrl,
    String? upc,
    double? matchConfidence,
  }) {
    return ProductMatch(
      source: source ?? this.source,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      imageUrl: imageUrl ?? this.imageUrl,
      currentPrice: currentPrice ?? this.currentPrice,
      usedPrice: usedPrice ?? this.usedPrice,
      productUrl: productUrl ?? this.productUrl,
      upc: upc ?? this.upc,
      matchConfidence: matchConfidence ?? this.matchConfidence,
    );
  }

  @override
  List<Object?> get props => [
    source,
    productName,
    brand,
    model,
    imageUrl,
    currentPrice,
    usedPrice,
    productUrl,
    upc,
    matchConfidence,
  ];
}

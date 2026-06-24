import '../entities/product_match.dart';
import '../entities/receipt.dart';

/// Repository interface for product lookups and price tracking.
abstract class ProductRepository {
  /// Search for products by name/keywords.
  Future<List<ProductMatch>> searchProducts(String query, {String? brand});

  /// Look up a product by barcode (UPC/EAN).
  Future<ProductMatch?> lookupBarcode(String barcode);

  /// Extract product metadata from a URL (OpenGraph, JSON-LD).
  Future<ProductMatch?> lookupUrl(String url);

  /// Record a price observation for an item.
  Future<void> recordPrice(String itemId, double price, String source);

  /// Watch the price history for an item.
  Stream<List<PriceHistoryEntry>> watchPriceHistory(String itemId);
}

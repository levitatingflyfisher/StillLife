import 'package:dio/dio.dart';
import 'package:still_life/features/store_integration/domain/entities/product_match.dart';

class UpcLookupService {
  final Dio _dio;

  const UpcLookupService(this._dio);

  Future<ProductMatch?> lookupBarcode(String barcode) async {
    final result = await _tryUpcItemDb(barcode);
    if (result != null) return result;
    return _tryOpenFoodFacts(barcode);
  }

  Future<ProductMatch?> _tryUpcItemDb(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.upcitemdb.com/prod/trial/lookup',
        queryParameters: {'upc': barcode},
      );
      final data = response.data;
      if (data == null) return null;

      final items = data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) return null;

      final item = items[0] as Map<String, dynamic>;
      final title = item['title'] as String?;
      if (title == null || title.isEmpty) return null;

      final images = item['images'] as List<dynamic>?;
      final offers = item['offers'] as List<dynamic>?;

      double? price;
      if (offers != null && offers.isNotEmpty) {
        final offer = offers[0] as Map<String, dynamic>;
        price = (offer['price'] as num?)?.toDouble();
      }

      return ProductMatch(
        source: 'upc_itemdb',
        productName: title,
        brand: item['brand'] as String?,
        imageUrl: (images != null && images.isNotEmpty)
            ? images[0] as String?
            : null,
        currentPrice: price,
        upc: (item['ean'] as String?) ?? barcode,
        matchConfidence: 0.8,
      );
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ProductMatch?> _tryOpenFoodFacts(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );
      final data = response.data;
      if (data == null) return null;
      if (data['status'] != 1) return null;

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final name = product['product_name'] as String?;
      if (name == null || name.isEmpty) return null;

      return ProductMatch(
        source: 'open_food_facts',
        productName: name,
        brand: product['brands'] as String?,
        imageUrl: product['image_url'] as String?,
        upc: barcode,
        matchConfidence: 0.7,
      );
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}

import 'package:dio/dio.dart';

import '../database/database.dart';

class ProductInfo {
  final String name;
  final String? description;
  final String? brand;

  const ProductInfo({required this.name, this.description, this.brand});
}

/// Looks up product details by barcode.
///
/// Strategy (in order):
///   1. Local Drift cache — zero network, zero privacy cost.
///   2. Network (Open Food Facts → UPCitemdb fallback) — only when
///      [allowNetwork] is true (explicit user opt-in).  Results are written
///      back to the cache so each barcode is only ever fetched once.
class ProductLookupService {
  final Dio _dio;
  final AppDatabase _db;

  ProductLookupService(this._dio, this._db);

  Future<ProductInfo?> lookup(
    String barcode, {
    bool allowNetwork = false,
  }) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return null;

    // 1. Local cache
    final cached = await _db.getCachedProduct(trimmed);
    if (cached != null) {
      return ProductInfo(
        name: cached.name,
        description: cached.description,
        brand: cached.brand,
      );
    }

    // 2. Network (opt-in only)
    if (!allowNetwork) return null;

    final info = await _networkLookup(trimmed);
    if (info != null) {
      await _db.cacheProduct(
        trimmed,
        info.name,
        description: info.description,
        brand: info.brand,
      );
    }
    return info;
  }

  Future<ProductInfo?> _networkLookup(String barcode) async {
    // Try Open Food Facts first
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://world.openfoodfacts.org/api/v2/product/$barcode',
        queryParameters: {'fields': 'product_name,brands'},
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );
      if (response.statusCode == 200 && response.data?['status'] == 1) {
        final product =
            response.data!['product'] as Map<String, dynamic>? ?? {};
        final name = (product['product_name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          final brand = (product['brands'] as String?)?.trim();
          return ProductInfo(
            name: name,
            brand: brand?.isNotEmpty == true ? brand : null,
            description: brand?.isNotEmpty == true ? 'Brand: $brand' : null,
          );
        }
      }
    } catch (_) {}

    // Fall back to UPCitemdb (trial tier — 100 req/day, no key required)
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.upcitemdb.com/prod/trial/lookup',
        queryParameters: {'upc': barcode},
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );
      if (response.statusCode == 200 && response.data?['code'] == 'OK') {
        final items = (response.data!['items'] as List?)
            ?.cast<Map<String, dynamic>>();
        if (items != null && items.isNotEmpty) {
          final item = items.first;
          final name = (item['title'] as String?)?.trim();
          final desc = (item['description'] as String?)?.trim();
          final brand = (item['brand'] as String?)?.trim();
          if (name != null && name.isNotEmpty) {
            return ProductInfo(
              name: name,
              description: desc?.isNotEmpty == true ? desc : null,
              brand: brand?.isNotEmpty == true ? brand : null,
            );
          }
        }
      }
    } catch (_) {}

    return null;
  }
}

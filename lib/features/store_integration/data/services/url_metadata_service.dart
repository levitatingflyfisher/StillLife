import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:still_life/features/store_integration/domain/entities/product_match.dart';

class UrlMetadataService {
  final Dio _dio;

  const UrlMetadataService(this._dio);

  Future<ProductMatch?> extractMetadata(String url) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': 'Mozilla/5.0 (compatible; StillLife/1.0)'},
        ),
      );
      final body = response.data;
      if (body == null || body.isEmpty) return null;

      final document = html_parser.parse(body);

      final ogTitle = _metaContent(document, 'og:title');
      final ogImage = _metaContent(document, 'og:image');
      final ogPrice =
          _metaContent(document, 'og:price:amount') ??
          _metaContent(document, 'product:price:amount');

      String? ldName;
      String? ldBrand;
      String? ldImage;
      double? ldPrice;

      for (final script in document.querySelectorAll(
        'script[type="application/ld+json"]',
      )) {
        try {
          final json = jsonDecode(script.text);
          final product = _findProduct(json);
          if (product is Map<String, dynamic>) {
            ldName = product['name'] as String?;
            ldBrand = _extractBrand(product['brand']);
            ldImage = _extractImage(product['image']);
            ldPrice = _extractLdPrice(product['offers']);
          }
        } catch (_) {
          // Skip malformed JSON-LD
        }
      }

      final productName = ldName ?? ogTitle;
      if (productName == null || productName.isEmpty) return null;

      double? price = ldPrice;
      if (price == null && ogPrice != null) {
        price = double.tryParse(ogPrice);
      }

      return ProductMatch(
        source: 'url_metadata',
        productName: productName,
        brand: ldBrand,
        imageUrl: ldImage ?? ogImage,
        currentPrice: price,
        productUrl: url,
        matchConfidence: 0.6,
      );
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _metaContent(dynamic document, String property) {
    final element = document.querySelector('meta[property="$property"]');
    return element?.attributes['content'];
  }

  dynamic _findProduct(dynamic json) {
    if (json is Map<String, dynamic>) {
      if (json['@type'] == 'Product') return json;
      if (json['@graph'] is List) {
        for (final item in json['@graph'] as List) {
          final result = _findProduct(item);
          if (result != null) return result;
        }
      }
    }
    if (json is List) {
      for (final item in json) {
        final result = _findProduct(item);
        if (result != null) return result;
      }
    }
    return null;
  }

  String? _extractBrand(dynamic brand) {
    if (brand is String) return brand;
    if (brand is Map<String, dynamic>) return brand['name'] as String?;
    return null;
  }

  String? _extractImage(dynamic image) {
    if (image is String) return image;
    if (image is List && image.isNotEmpty) {
      return _extractImage(image.first);
    }
    if (image is Map<String, dynamic>) return image['url'] as String?;
    return null;
  }

  double? _extractLdPrice(dynamic offers) {
    if (offers is Map<String, dynamic>) {
      final price = offers['price'];
      if (price is num) return price.toDouble();
      if (price is String) return double.tryParse(price);
    }
    if (offers is List && offers.isNotEmpty) {
      return _extractLdPrice(offers.first);
    }
    return null;
  }
}

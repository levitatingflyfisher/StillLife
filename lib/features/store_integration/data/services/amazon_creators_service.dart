import 'package:dio/dio.dart';
import 'package:still_life/features/store_integration/domain/entities/product_match.dart';

class AmazonCreatorsService {
  final Dio dio;
  final String? affiliateTag;

  const AmazonCreatorsService(this.dio, {this.affiliateTag});

  // Amazon Product Advertising API integration is not yet implemented.
  // Returns an empty result set.
  Future<List<ProductMatch>> searchProducts(
    String query, {
    String? brand,
  }) async {
    return const [];
  }
}

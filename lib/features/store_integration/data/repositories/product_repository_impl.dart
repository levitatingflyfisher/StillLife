import 'package:still_life/features/store_integration/data/services/upc_lookup_service.dart';
import 'package:still_life/features/store_integration/data/services/url_metadata_service.dart';
import 'package:still_life/features/store_integration/domain/entities/product_match.dart';
import 'package:still_life/features/store_integration/domain/entities/receipt.dart'
    as domain;
import 'package:still_life/features/store_integration/domain/repositories/product_repository.dart';
import 'package:still_life/services/database/daos/price_history_dao.dart';
import 'package:still_life/services/database/database.dart';
import 'package:uuid/uuid.dart';

class ProductRepositoryImpl implements ProductRepository {
  final UpcLookupService _upcLookupService;
  final UrlMetadataService _urlMetadataService;
  final PriceHistoryDao _priceHistoryDao;

  static const _uuid = Uuid();

  const ProductRepositoryImpl(
    this._upcLookupService,
    this._urlMetadataService,
    this._priceHistoryDao,
  );

  @override
  Future<List<ProductMatch>> searchProducts(
    String query, {
    String? brand,
  }) async {
    // Delegate to UPC lookup service — search by query as a barcode.
    // If the query looks like a barcode, try a direct lookup.
    final result = await _upcLookupService.lookupBarcode(query);
    if (result != null) {
      return [result];
    }
    return [];
  }

  @override
  Future<ProductMatch?> lookupBarcode(String barcode) {
    return _upcLookupService.lookupBarcode(barcode);
  }

  @override
  Future<ProductMatch?> lookupUrl(String url) {
    return _urlMetadataService.extractMetadata(url);
  }

  @override
  Future<void> recordPrice(String itemId, double price, String source) {
    final now = DateTime.now();
    return _priceHistoryDao.insertPriceEntry(
      PriceHistoryEntriesCompanion.insert(
        id: _uuid.v4(),
        itemId: itemId,
        price: price,
        source: source,
        recordedAt: now,
      ),
    );
  }

  @override
  Stream<List<domain.PriceHistoryEntry>> watchPriceHistory(String itemId) {
    return _priceHistoryDao
        .watchPriceHistory(itemId)
        .map(
          (entries) => entries
              .map(
                (e) => domain.PriceHistoryEntry(
                  id: e.id,
                  itemId: e.itemId,
                  price: e.price,
                  source: e.source,
                  recordedAt: e.recordedAt,
                ),
              )
              .toList(),
        );
  }
}

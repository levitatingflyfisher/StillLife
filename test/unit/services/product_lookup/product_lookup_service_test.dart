import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/product_lookup/product_lookup_service.dart';

class _MockDio extends Mock implements Dio {}

class _MockDb extends Mock implements AppDatabase {}

Response<Map<String, dynamic>> _fakeResponse(
  Map<String, dynamic> data, {
  int statusCode = 200,
}) => Response<Map<String, dynamic>>(
  data: data,
  statusCode: statusCode,
  requestOptions: RequestOptions(path: ''),
);

void main() {
  late _MockDio dio;
  late _MockDb db;
  late ProductLookupService service;

  setUp(() {
    dio = _MockDio();
    db = _MockDb();
    service = ProductLookupService(dio, db);
    // Default: no cached entry
    when(() => db.getCachedProduct(any())).thenAnswer((_) async => null);
    when(
      () => db.cacheProduct(
        any(),
        any(),
        description: any(named: 'description'),
        brand: any(named: 'brand'),
      ),
    ).thenAnswer((_) async {});
  });

  group('ProductLookupService.lookup', () {
    test(
      'returns null for empty barcode without hitting network or cache',
      () async {
        final result = await service.lookup('');
        expect(result, isNull);
        verifyNever(() => db.getCachedProduct(any()));
      },
    );

    test('returns cached result without network call', () async {
      when(() => db.getCachedProduct('111')).thenAnswer(
        (_) async => ProductLookupCacheData(
          barcode: '111',
          name: 'Cached Item',
          description: null,
          brand: 'ACME',
          cachedAt: DateTime(2024),
        ),
      );

      final info = await service.lookup('111', allowNetwork: true);

      expect(info!.name, 'Cached Item');
      expect(info.brand, 'ACME');
      // No network call made
      verifyNever(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      );
    });

    test('returns null on cache miss when allowNetwork is false', () async {
      final result = await service.lookup('999', allowNetwork: false);
      expect(result, isNull);
      verifyNever(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      );
    });

    test('parses Open Food Facts and caches result', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => _fakeResponse({
          'status': 1,
          'product': {'product_name': 'Organic Oats', 'brands': 'Nature Co'},
        }),
      );

      final info = await service.lookup('0123456789', allowNetwork: true);

      expect(info!.name, 'Organic Oats');
      verify(
        () => db.cacheProduct(
          '0123456789',
          'Organic Oats',
          description: any(named: 'description'),
          brand: any(named: 'brand'),
        ),
      ).called(1);
    });

    test('falls back to UPCitemdb when OFF returns no product name', () async {
      var callCount = 0;
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return _fakeResponse({'status': 1, 'product': <String, dynamic>{}});
        }
        return _fakeResponse({
          'code': 'OK',
          'items': [
            {
              'title': 'Widget Pro',
              'description': 'Great widget',
              'brand': 'Co',
            },
          ],
        });
      });

      final info = await service.lookup('111', allowNetwork: true);
      expect(info!.name, 'Widget Pro');
    });

    test('returns null when both APIs fail', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await service.lookup('9999', allowNetwork: true);
      expect(result, isNull);
    });

    test('trims whitespace from barcode', () async {
      when(() => db.getCachedProduct('123abc')).thenAnswer((_) async => null);
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _fakeResponse({'status': 0}));

      await service.lookup('  123abc  ', allowNetwork: true);

      verify(() => db.getCachedProduct('123abc')).called(1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/appraisal/domain/entities/appraisal.dart';
import 'package:still_life/features/appraisal/domain/entities/appraisal_source.dart';
import 'package:still_life/features/appraisal/domain/repositories/appraisal_repository.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/services/appraisal/appraiser_service.dart';

class _FakeRepo implements AppraisalRepository {
  final List<Appraisal> store = [];
  int saveCalls = 0;
  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Appraisal?> getLatestByCacheKey(
    String itemModelKey,
    AppraisalMode mode,
    String countryCode,
  ) async {
    for (final a in store) {
      if (a.itemModelKey == itemModelKey &&
          a.mode == mode &&
          a.countryCode == countryCode &&
          a.isFresh) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<Appraisal?> getLatestByItemAndMode(
    String itemId,
    AppraisalMode mode,
  ) async {
    for (final a in store) {
      if (a.itemId == itemId && a.mode == mode && a.isFresh) return a;
    }
    return null;
  }

  @override
  Future<Result<Appraisal>> save(Appraisal a) async {
    saveCalls++;
    final withId = a.id.isEmpty ? a.copyWith() : a;
    store.add(withId);
    return Success(withId);
  }

  @override
  Stream<List<Appraisal>> watchForItem(String itemId) =>
      Stream.value(store.where((a) => a.itemId == itemId).toList());
}

class _FakeTransport implements MessagesTransport {
  final List<Map<String, dynamic>> calls = [];
  Result<Map<String, dynamic>> Function(Map<String, dynamic>) handler;
  _FakeTransport(this.handler);
  @override
  Future<Result<Map<String, dynamic>>> send(Map<String, dynamic> body) async {
    calls.add(body);
    return handler(body);
  }
}

Item sampleItem({String id = 'i1', String name = 'Samsung TV'}) => Item(
  id: id,
  name: name,
  description: '',
  categoryId: 'c',
  roomId: 'r',
  condition: ItemCondition.good,
  createdAt: DateTime(2024),
  modifiedAt: DateTime(2024),
);

Map<String, dynamic> cannedResponse({
  double value = 350,
  double confidence = 0.8,
}) => {
  'content': [
    {
      'type': 'text',
      'text':
          '{"value": $value, "currency": "USD", "confidence": $confidence, "sources": [{"url": "https://ebay.com/x", "title": "eBay listing", "price": 340.0}]}',
    },
  ],
};

void main() {
  group('AppraiserService.appraise', () {
    test('cache miss: calls transport, saves result', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport((_) => Success(cannedResponse()));
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
      );
      final r = await svc.appraise(sampleItem(), AppraisalMode.resale);
      expect(r.isSuccess, isTrue);
      expect(transport.calls, hasLength(1));
      expect(repo.saveCalls, 1);
      expect(repo.store.first.value, 350);
      expect(repo.store.first.sources.first.url, 'https://ebay.com/x');
    });

    test('cache hit for same item: no network call', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport((_) => Success(cannedResponse()));
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
      );
      await svc.appraise(sampleItem(), AppraisalMode.resale);
      transport.calls.clear();
      final r = await svc.appraise(sampleItem(), AppraisalMode.resale);
      expect(r.isSuccess, isTrue);
      expect(transport.calls, isEmpty);
    });

    test('cross-item cache reuse: no network, clones cached value', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport((_) => Success(cannedResponse()));
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
      );
      await svc.appraise(sampleItem(id: 'first'), AppraisalMode.resale);
      transport.calls.clear();
      final r = await svc.appraise(
        sampleItem(id: 'second'),
        AppraisalMode.resale,
      );
      expect(transport.calls, isEmpty);
      expect(r.value.itemId, 'second');
      expect(r.value.value, 350);
    });

    test('forceRefresh: bypasses cache', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport((_) => Success(cannedResponse()));
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
      );
      await svc.appraise(sampleItem(), AppraisalMode.resale);
      transport.calls.clear();
      await svc.appraise(
        sampleItem(),
        AppraisalMode.resale,
        forceRefresh: true,
      );
      expect(transport.calls, hasLength(1));
    });

    test('parse failure: returns ValidationFailure', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport(
        (_) => const Success({
          'content': [
            {'type': 'text', 'text': 'this is not JSON'},
          ],
        }),
      );
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
      );
      final r = await svc.appraise(sampleItem(), AppraisalMode.resale);
      expect(r.isFailure, isTrue);
      expect(r.failure, isA<ValidationFailure>());
    });

    test('transport failure: propagates', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport(
        (_) => const Err(NetworkFailure('boom')),
      );
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
      );
      final r = await svc.appraise(sampleItem(), AppraisalMode.resale);
      expect(r.isFailure, isTrue);
      expect(r.failure, isA<NetworkFailure>());
    });

    test('replace_new uses 7-day TTL', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport((_) => Success(cannedResponse()));
      final fixedNow = DateTime(2025, 6, 1);
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
        now: () => fixedNow,
      );
      await svc.appraise(sampleItem(), AppraisalMode.replaceNew);
      final saved = repo.store.first;
      expect(saved.expiresAt, fixedNow.add(const Duration(days: 7)));
    });

    test('resale uses 30-day TTL', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport((_) => Success(cannedResponse()));
      final fixedNow = DateTime(2025, 6, 1);
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
        now: () => fixedNow,
      );
      await svc.appraise(sampleItem(), AppraisalMode.resale);
      final saved = repo.store.first;
      expect(saved.expiresAt, fixedNow.add(const Duration(days: 30)));
    });
  });

  group('AppraiserService._parseResponse indirect', () {
    test('tolerates prose around JSON', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport(
        (_) => const Success({
          'content': [
            {
              'type': 'text',
              'text':
                  'Sure — {"value": 42, "currency": "USD", "confidence": 0.9, "sources": []}.',
            },
          ],
        }),
      );
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
      );
      final r = await svc.appraise(sampleItem(), AppraisalMode.resale);
      expect(r.isSuccess, isTrue);
      expect(r.value.value, 42);
    });

    test('null value field defaults to 0.0 instead of crashing', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport(
        (_) => const Success({
          'content': [
            {
              'type': 'text',
              'text': '{"value": null, "currency": "USD", "sources": []}',
            },
          ],
        }),
      );
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
      );
      final r = await svc.appraise(sampleItem(), AppraisalMode.resale);
      expect(r.isSuccess, isTrue);
      expect(r.value.value, 0.0);
    });

    test('missing currency defaults to USD, missing confidence to 0', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport(
        (_) => const Success({
          'content': [
            {'type': 'text', 'text': '{"value": 100, "sources": []}'},
          ],
        }),
      );
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
      );
      final r = await svc.appraise(sampleItem(), AppraisalMode.resale);
      expect(r.isSuccess, isTrue);
      expect(r.value.currency, 'USD');
      expect(r.value.confidence, 0.0);
    });

    test('source with missing url is filtered out', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport(
        (_) => const Success({
          'content': [
            {
              'type': 'text',
              'text':
                  '{"value": 100, "currency": "USD", "sources": [{"title": "no url here"}, {"url": "https://x", "title": "ok"}]}',
            },
          ],
        }),
      );
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
      );
      final r = await svc.appraise(sampleItem(), AppraisalMode.resale);
      expect(r.isSuccess, isTrue);
      expect(r.value.sources, hasLength(1));
      expect(r.value.sources.first.url, 'https://x');
    });
  });

  group('AppraiserService cross-item cache TTL refresh', () {
    test('cloned cache uses fresh TTL, not the cached row\'s TTL', () async {
      final repo = _FakeRepo();
      final transport = _FakeTransport((_) => Success(cannedResponse()));
      final t0 = DateTime(2025, 6, 1);
      DateTime now = t0;
      final svc = AppraiserService(
        repo: repo,
        transport: transport,
        countryCode: () => 'US',
        now: () => now,
      );
      await svc.appraise(sampleItem(id: 'first'), AppraisalMode.resale);
      // Advance 25 days so the original cache row is 5 days from expiry.
      now = t0.add(const Duration(days: 25));
      final r = await svc.appraise(
        sampleItem(id: 'second'),
        AppraisalMode.resale,
      );
      expect(r.isSuccess, isTrue);
      // Cloned row's expiresAt should be `now + 30d`, not the original
      // expiry (t0 + 30d, which would now be 5 days away).
      expect(r.value.expiresAt, now.add(const Duration(days: 30)));
    });
  });

  // Ensure unused import warnings don't trigger.
  const AppraisalSource(url: 'x', title: 'y');
}

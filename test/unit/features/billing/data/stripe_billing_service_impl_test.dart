import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/features/billing/data/stripe_billing_service_impl.dart';
import 'package:still_life/features/billing/domain/account.dart';

class _FakeStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late _FakeStorage storage;
  late StripeBillingServiceImpl svc;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    adapter = DioAdapter(dio: dio);
    storage = _FakeStorage();
    when(
      () => storage.read(key: kHostedBearerStorageKey),
    ).thenAnswer((_) async => 'sl_live_abc');
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    svc = StripeBillingServiceImpl(
      dio: dio,
      storage: storage,
      baseUrl: 'https://api.test',
      checkoutUrl: Uri.parse('https://checkout.test'),
    );
  });

  test('getAccount parses JSON', () async {
    adapter.onGet(
      'https://api.test/v1/account',
      (s) => s.reply(200, {
        'tier': 'pro',
        'status': 'active',
        'tokens_used_month': 1234,
        'tokens_month_cap': 50000,
        'month_reset_at': 1712000000000,
      }),
      headers: {'Authorization': 'Bearer sl_live_abc'},
    );

    final res = await svc.getAccount();
    res.when(
      success: (a) {
        expect(a.tokensUsedMonth, 1234);
        expect(a.status, SubscriptionStatus.active);
        expect(a.tokensMonthCap, 50000);
      },
      failure: (f) => fail('expected success: ${f.message}'),
    );
  });

  test('activate stores returned bearer', () async {
    adapter.onPost(
      'https://api.test/v1/activate',
      (s) => s.reply(200, {
        'bearer': 'sl_live_new',
        'tier': 'pro',
        'tokens_month_cap': 50000,
        'month_reset_at': 1712,
      }),
      data: {'session_id': 'cs_abc'},
    );

    final res = await svc.activate('cs_abc');
    res.when(
      success: (_) {
        verify(
          () =>
              storage.write(key: kHostedBearerStorageKey, value: 'sl_live_new'),
        ).called(1);
      },
      failure: (f) => fail(f.message),
    );
  });

  test('deleteAccount clears bearer on 204', () async {
    adapter.onDelete(
      'https://api.test/v1/account',
      (s) => s.reply(204, null),
      headers: {'Authorization': 'Bearer sl_live_abc'},
    );
    final res = await svc.deleteAccount();
    res.when(
      success: (_) {
        verify(() => storage.delete(key: kHostedBearerStorageKey)).called(1);
      },
      failure: (f) => fail(f.message),
    );
  });

  test('getAccount with missing bearer returns ValidationFailure', () async {
    when(
      () => storage.read(key: kHostedBearerStorageKey),
    ).thenAnswer((_) async => null);
    final res = await svc.getAccount();
    expect(res.isFailure, isTrue);
  });

  test('getAccount on 401 clears stored bearer', () async {
    adapter.onGet(
      'https://api.test/v1/account',
      (s) => s.reply(401, {'error': 'invalid_bearer'}),
      headers: {'Authorization': 'Bearer sl_live_abc'},
    );
    final res = await svc.getAccount();
    expect(res.isFailure, isTrue);
    verify(() => storage.delete(key: kHostedBearerStorageKey)).called(1);
  });

  test('rotateBearer stores the new bearer', () async {
    adapter.onPost(
      'https://api.test/v1/rotate',
      (s) => s.reply(200, {'bearer': 'sl_live_rotated'}),
      headers: {'Authorization': 'Bearer sl_live_abc'},
    );
    final res = await svc.rotateBearer();
    res.when(
      success: (_) {
        verify(
          () => storage.write(
            key: kHostedBearerStorageKey,
            value: 'sl_live_rotated',
          ),
        ).called(1);
      },
      failure: (f) => fail(f.message),
    );
  });

  test('hasBearer returns true when storage has a non-empty value', () async {
    expect(await svc.hasBearer(), isTrue);
    when(
      () => storage.read(key: kHostedBearerStorageKey),
    ).thenAnswer((_) async => '');
    expect(await svc.hasBearer(), isFalse);
    when(
      () => storage.read(key: kHostedBearerStorageKey),
    ).thenAnswer((_) async => null);
    expect(await svc.hasBearer(), isFalse);
  });

  test('buildCheckoutUrl returns configured uri', () {
    expect(svc.buildCheckoutUrl(), Uri.parse('https://checkout.test'));
  });
}

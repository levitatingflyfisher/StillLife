import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/billing/domain/account.dart';
import 'package:still_life/features/billing/domain/billing_service.dart';

/// Bearer-key storage slot used by both [StripeBillingServiceImpl] and
/// [HostedProvider]'s `apiKeyProvider` — kept as a public constant so the
/// two stay in sync.
const String kHostedBearerStorageKey = 'hosted_bearer';

/// Dio + FlutterSecureStorage backed implementation of [BillingService].
///
/// The bearer is read from secure storage on every call (so rotations are
/// picked up without restarting providers). 401 responses self-heal by
/// clearing the stored bearer; the caller is expected to re-watch
/// `accountProvider` to pick up the cleared state.
class StripeBillingServiceImpl implements BillingService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String baseUrl;
  final Uri _checkoutUrl;

  StripeBillingServiceImpl({
    required Dio dio,
    required FlutterSecureStorage storage,
    required this.baseUrl,
    required Uri checkoutUrl,
  }) : _dio = dio,
       _storage = storage,
       _checkoutUrl = checkoutUrl;

  @override
  Uri buildCheckoutUrl() => _checkoutUrl;

  @override
  Future<bool> hasBearer() async {
    final v = await _storage.read(key: kHostedBearerStorageKey);
    return v != null && v.isNotEmpty;
  }

  @override
  Future<Result<Account>> getAccount() async {
    final bearer = await _storage.read(key: kHostedBearerStorageKey);
    if (bearer == null || bearer.isEmpty) {
      return const Err(ValidationFailure('No bearer'));
    }
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/v1/account',
        options: Options(headers: {'Authorization': 'Bearer $bearer'}),
      );
      final j = r.data!;
      return Success(
        Account(
          tier: j['tier'] as String,
          status: _parseStatus(j['status'] as String),
          tokensUsedMonth: j['tokens_used_month'] as int,
          tokensMonthCap: j['tokens_month_cap'] as int,
          monthResetAt: DateTime.fromMillisecondsSinceEpoch(
            j['month_reset_at'] as int,
          ),
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.delete(key: kHostedBearerStorageKey);
      }
      return Err(NetworkFailure('getAccount: ${e.message}'));
    }
  }

  @override
  Future<Result<void>> activate(String sessionId) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/v1/activate',
        data: {'session_id': sessionId},
      );
      final bearer = r.data?['bearer'] as String?;
      if (bearer == null) {
        return const Err(ValidationFailure('No bearer returned'));
      }
      await _storage.write(key: kHostedBearerStorageKey, value: bearer);
      return const Success(null);
    } on DioException catch (e) {
      return Err(NetworkFailure('activate: ${e.message}'));
    }
  }

  @override
  Future<Result<void>> rotateBearer() async {
    final bearer = await _storage.read(key: kHostedBearerStorageKey);
    if (bearer == null) {
      return const Err(ValidationFailure('No bearer to rotate'));
    }
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/v1/rotate',
        options: Options(headers: {'Authorization': 'Bearer $bearer'}),
      );
      await _storage.write(
        key: kHostedBearerStorageKey,
        value: r.data!['bearer'] as String,
      );
      return const Success(null);
    } on DioException catch (e) {
      return Err(NetworkFailure('rotate: ${e.message}'));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    final bearer = await _storage.read(key: kHostedBearerStorageKey);
    if (bearer == null) {
      return const Err(ValidationFailure('No bearer'));
    }
    try {
      await _dio.delete<dynamic>(
        '$baseUrl/v1/account',
        options: Options(headers: {'Authorization': 'Bearer $bearer'}),
      );
      await _storage.delete(key: kHostedBearerStorageKey);
      return const Success(null);
    } on DioException catch (e) {
      return Err(NetworkFailure('delete: ${e.message}'));
    }
  }

  SubscriptionStatus _parseStatus(String s) {
    switch (s) {
      case 'active':
        return SubscriptionStatus.active;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'canceled':
        return SubscriptionStatus.canceled;
      default:
        return SubscriptionStatus.none;
    }
  }
}

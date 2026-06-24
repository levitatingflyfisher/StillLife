import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/reports/data/repositories/policy_repository_impl.dart';
import 'package:still_life/features/reports/domain/entities/policy.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;

import '../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  late PolicyRepositoryImpl repo;
  final now = DateTime(2025, 6, 1);

  setUp(() async {
    database = db_pkg.AppDatabase(NativeDatabase.memory());
    repo = PolicyRepositoryImpl(database);
    await database
        .into(database.properties)
        .insert(
          db_pkg.PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Test Home',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() => database.close());

  Policy makePolicy({
    String id = 'pol1',
    String provider = 'State Farm',
    double? coverage = 200000,
    DateTime? expiry,
  }) => Policy(
    id: id,
    propertyId: 'prop1',
    provider: provider,
    policyNumber: 'SF-12345',
    coverageAmount: coverage,
    deductible: 1000,
    premium: 1200,
    expiryDate: expiry,
    createdAt: now,
  );

  group('PolicyRepositoryImpl', () {
    test('create and watchAll round-trip', () async {
      final policy = makePolicy();
      final result = await repo.create(policy);
      expect(result, isA<Success<Policy>>());
      expect((result as Success<Policy>).value.provider, 'State Farm');

      final stream = repo.watchAll();
      final list = await stream.first;
      expect(list, hasLength(1));
      expect(list.first.id, 'pol1');
      expect(list.first.coverageAmount, 200000);
    });

    test('create assigns generated id when empty', () async {
      final policy = makePolicy(id: '');
      final result = await repo.create(policy);
      expect(result, isA<Success<Policy>>());
      final created = (result as Success<Policy>).value;
      expect(created.id, isNotEmpty);
      expect(created.id, isNot(''));
    });

    test('update modifies fields', () async {
      await repo.create(makePolicy());
      final updated = makePolicy(provider: 'Allstate', coverage: 300000);
      final result = await repo.update(updated);
      expect(result, isA<Success<Policy>>());
      expect((result as Success<Policy>).value.provider, 'Allstate');
      expect(result.value.coverageAmount, 300000);
    });

    test('update returns Err for non-existent id', () async {
      final result = await repo.update(makePolicy(id: 'ghost'));
      expect(result, isA<Err>());
    });

    test('delete removes policy', () async {
      await repo.create(makePolicy());
      final deleteResult = await repo.delete('pol1');
      expect(deleteResult, isA<Success>());

      final list = await repo.watchAll().first;
      expect(list, isEmpty);
    });

    test('getByPropertyId filters correctly', () async {
      // Insert a second property + policy
      await database
          .into(database.properties)
          .insert(
            db_pkg.PropertiesCompanion.insert(
              id: 'prop2',
              name: 'Second Home',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await repo.create(makePolicy(id: 'pol1'));
      await repo.create(
        Policy(
          id: 'pol2',
          propertyId: 'prop2',
          provider: 'Geico',
          createdAt: now,
        ),
      );

      final result = await repo.getByPropertyId('prop1');
      expect(result, isA<Success<List<Policy>>>());
      final list = (result as Success<List<Policy>>).value;
      expect(list, hasLength(1));
      expect(list.first.id, 'pol1');
    });

    test('watchAll emits updated list reactively', () async {
      final stream = repo.watchAll();
      // Initially empty
      expect(await stream.first, isEmpty);
      // After insert, stream emits updated list
      await repo.create(makePolicy());
      expect(await stream.first, hasLength(1));
    });
  });
}

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    // Insert a property first since policies reference properties via FK.
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Test Home',
            createdAt: DateTime(2025, 1, 1),
            modifiedAt: DateTime(2025, 1, 1),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('PolicyDao', () {
    PoliciesCompanion makePolicy({
      String id = 'pol1',
      String propertyId = 'prop1',
      String provider = 'State Farm',
    }) {
      return PoliciesCompanion.insert(
        id: id,
        propertyId: propertyId,
        provider: provider,
        createdAt: DateTime(2025, 6, 1),
        modifiedAt: DateTime(2025, 6, 1),
      );
    }

    test('insertPolicy and getById', () async {
      await db.policyDao.insertPolicy(makePolicy());

      final result = await db.policyDao.getById('pol1');
      expect(result, isNotNull);
      expect(result!.id, 'pol1');
      expect(result.provider, 'State Farm');
      expect(result.propertyId, 'prop1');
    });

    test('getById returns null for non-existent id', () async {
      final result = await db.policyDao.getById('nonexistent');
      expect(result, isNull);
    });

    test('getAll returns all policies', () async {
      await db.policyDao.insertPolicy(makePolicy(id: 'pol1'));
      await db.policyDao.insertPolicy(
        makePolicy(id: 'pol2', provider: 'Allstate'),
      );

      final results = await db.policyDao.getAll();
      expect(results, hasLength(2));
    });

    test('getByPropertyId filters by property', () async {
      // Insert a second property.
      await db
          .into(db.properties)
          .insert(
            PropertiesCompanion.insert(
              id: 'prop2',
              name: 'Vacation Home',
              createdAt: DateTime(2025, 1, 1),
              modifiedAt: DateTime(2025, 1, 1),
            ),
          );

      await db.policyDao.insertPolicy(
        makePolicy(id: 'pol1', propertyId: 'prop1'),
      );
      await db.policyDao.insertPolicy(
        makePolicy(id: 'pol2', propertyId: 'prop2'),
      );
      await db.policyDao.insertPolicy(
        makePolicy(id: 'pol3', propertyId: 'prop1'),
      );

      final prop1Policies = await db.policyDao.getByPropertyId('prop1');
      expect(prop1Policies, hasLength(2));

      final prop2Policies = await db.policyDao.getByPropertyId('prop2');
      expect(prop2Policies, hasLength(1));
    });

    test('updatePolicy modifies existing policy', () async {
      await db.policyDao.insertPolicy(makePolicy());

      final updated = await db.policyDao.updatePolicy(
        const PoliciesCompanion(id: Value('pol1'), provider: Value('Allstate')),
      );
      expect(updated, isTrue);

      final result = await db.policyDao.getById('pol1');
      expect(result!.provider, 'Allstate');
    });

    test('updatePolicy returns false for non-existent id', () async {
      final updated = await db.policyDao.updatePolicy(
        const PoliciesCompanion(
          id: Value('nonexistent'),
          provider: Value('Whatever'),
        ),
      );
      expect(updated, isFalse);
    });

    test('deletePolicy removes the policy', () async {
      await db.policyDao.insertPolicy(makePolicy());

      final deleted = await db.policyDao.deletePolicy('pol1');
      expect(deleted, 1);

      final result = await db.policyDao.getById('pol1');
      expect(result, isNull);
    });

    test('deletePolicy returns 0 for non-existent id', () async {
      final deleted = await db.policyDao.deletePolicy('nonexistent');
      expect(deleted, 0);
    });

    test('watchAll emits updates', () async {
      // Verify initial state is empty.
      final initial = await db.policyDao.watchAll().first;
      expect(initial, isEmpty);

      // Insert a policy and verify the stream reflects it.
      await db.policyDao.insertPolicy(makePolicy());
      final updated = await db.policyDao.watchAll().first;
      expect(updated, hasLength(1));
    });
  });
}

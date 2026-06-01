import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/reports/domain/entities/policy.dart';

void main() {
  group('Policy', () {
    final now = DateTime(2025, 6, 15);

    test('creates with required fields', () {
      final policy = Policy(
        id: 'p1',
        propertyId: 'prop1',
        provider: 'State Farm',
        createdAt: now,
      );

      expect(policy.id, 'p1');
      expect(policy.propertyId, 'prop1');
      expect(policy.provider, 'State Farm');
      expect(policy.policyNumber, isNull);
      expect(policy.coverageAmount, isNull);
      expect(policy.deductible, isNull);
      expect(policy.premium, isNull);
      expect(policy.expiryDate, isNull);
      expect(policy.createdAt, now);
    });

    test('creates with all fields', () {
      final expiry = DateTime(2026, 6, 15);
      final policy = Policy(
        id: 'p1',
        propertyId: 'prop1',
        provider: 'Allstate',
        policyNumber: 'POL-12345',
        coverageAmount: 500000.0,
        deductible: 1000.0,
        premium: 1200.0,
        expiryDate: expiry,
        createdAt: now,
      );

      expect(policy.policyNumber, 'POL-12345');
      expect(policy.coverageAmount, 500000.0);
      expect(policy.deductible, 1000.0);
      expect(policy.premium, 1200.0);
      expect(policy.expiryDate, expiry);
    });

    test('copyWith replaces fields', () {
      final policy = Policy(
        id: 'p1',
        propertyId: 'prop1',
        provider: 'State Farm',
        createdAt: now,
      );

      final updated = policy.copyWith(
        provider: 'Allstate',
        coverageAmount: 300000.0,
      );

      expect(updated.id, 'p1');
      expect(updated.provider, 'Allstate');
      expect(updated.coverageAmount, 300000.0);
      expect(updated.propertyId, 'prop1');
    });

    test('isExpired returns true for past expiry date', () {
      final policy = Policy(
        id: 'p1',
        propertyId: 'prop1',
        provider: 'State Farm',
        expiryDate: DateTime(2020, 1, 1),
        createdAt: now,
      );

      expect(policy.isExpired, isTrue);
    });

    test('isExpired returns false for future expiry date', () {
      final policy = Policy(
        id: 'p1',
        propertyId: 'prop1',
        provider: 'State Farm',
        expiryDate: DateTime(2099, 12, 31),
        createdAt: now,
      );

      expect(policy.isExpired, isFalse);
    });

    test('isExpired returns false when expiryDate is null', () {
      final policy = Policy(
        id: 'p1',
        propertyId: 'prop1',
        provider: 'State Farm',
        createdAt: now,
      );

      expect(policy.isExpired, isFalse);
    });

    test('equality is based on id only', () {
      final policy1 = Policy(
        id: 'p1',
        propertyId: 'prop1',
        provider: 'State Farm',
        createdAt: now,
      );

      final policy2 = Policy(
        id: 'p1',
        propertyId: 'prop2',
        provider: 'Allstate',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(policy1, equals(policy2));
    });

    test('different ids are not equal', () {
      final policy1 = Policy(
        id: 'p1',
        propertyId: 'prop1',
        provider: 'State Farm',
        createdAt: now,
      );

      final policy2 = Policy(
        id: 'p2',
        propertyId: 'prop1',
        provider: 'State Farm',
        createdAt: now,
      );

      expect(policy1, isNot(equals(policy2)));
    });
  });
}

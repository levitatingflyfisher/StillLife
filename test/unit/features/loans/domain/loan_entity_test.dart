// test/unit/features/loans/domain/loan_entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/loans/domain/entities/loan.dart';

void main() {
  final now = DateTime.now();

  Loan base() => Loan(
    id: 'l1',
    itemId: 'i1',
    itemName: 'Camera',
    borrowerName: 'Alice',
    createdAt: now,
    modifiedAt: now,
  );

  // NOTE: copyWith uses `T? Function()?` for nullable fields (e.g. expectedReturnDate, notes,
  // returnedAt). To SET a nullable field, wrap in a lambda: `() => value`.
  // To CLEAR a nullable field to null, use: `() => null`.
  // Passing `null` directly means "leave unchanged" — this is how the function-wrapper pattern works.

  group('isActive', () {
    test('true when returnedAt is null', () => expect(base().isActive, isTrue));
    test(
      'false when returnedAt is set',
      () => expect(base().copyWith(returnedAt: () => now).isActive, isFalse),
    );
  });

  group('isOverdue', () {
    test('true when active and past due date', () {
      final loan = base().copyWith(
        expectedReturnDate: () => now.subtract(const Duration(days: 1)),
      );
      expect(loan.isOverdue, isTrue);
    });
    test('false when returned even if past due', () {
      final loan = base().copyWith(
        expectedReturnDate: () => now.subtract(const Duration(days: 1)),
        returnedAt: () => now,
      );
      expect(loan.isOverdue, isFalse);
    });
    test('false when no due date', () => expect(base().isOverdue, isFalse));
  });

  group('isDueSoon', () {
    test('true when active and due within 3 days', () {
      final loan = base().copyWith(
        expectedReturnDate: () => now.add(const Duration(days: 2)),
      );
      expect(loan.isDueSoon, isTrue);
    });
    test('false when due in more than 3 days', () {
      final loan = base().copyWith(
        expectedReturnDate: () => now.add(const Duration(days: 5)),
      );
      expect(loan.isDueSoon, isFalse);
    });
    test('false when overdue', () {
      final loan = base().copyWith(
        expectedReturnDate: () => now.subtract(const Duration(days: 1)),
      );
      expect(loan.isDueSoon, isFalse);
    });
    test('true when due in exactly 3 days', () {
      final loan = base().copyWith(
        expectedReturnDate: () => now.add(const Duration(days: 3)),
      );
      expect(loan.isDueSoon, isTrue);
    });
    test('false when returned even if due within 3 days', () {
      final loan = base().copyWith(
        expectedReturnDate: () => now.add(const Duration(days: 1)),
        returnedAt: () => now,
      );
      expect(loan.isDueSoon, isFalse);
    });
  });

  test('copyWith preserves unset fields', () {
    final copy = base().copyWith(borrowerName: 'Bob');
    expect(copy.borrowerName, 'Bob');
    expect(copy.id, 'l1');
  });

  test('copyWith can clear nullable fields', () {
    final withDate = base().copyWith(
      expectedReturnDate: () => now.add(const Duration(days: 3)),
    );
    final cleared = withDate.copyWith(
      expectedReturnDate: () => null,
    ); // () => null clears the field
    expect(cleared.expectedReturnDate, isNull);
  });

  test('Equatable: two loans with same data are equal', () {
    expect(base(), equals(base()));
  });
}

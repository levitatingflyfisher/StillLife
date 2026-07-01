import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/loans/domain/entities/loan.dart';

Loan _loan({DateTime? expectedReturnDate, DateTime? returnedAt}) => Loan(
  id: 'l1',
  itemId: 'i1',
  itemName: 'Camera',
  borrowerName: 'Alice',
  expectedReturnDate: expectedReturnDate,
  returnedAt: returnedAt,
  createdAt: DateTime(2026, 1, 1),
  modifiedAt: DateTime(2026, 1, 1),
);

void main() {
  // isOverdue/isDueSoon must read the injectable clock, not the wall
  // clock directly — otherwise every test (and golden PNG) that renders
  // them is correct only on the day it was written.
  group('Loan date getters honor withClock', () {
    final loan = _loan(expectedReturnDate: DateTime(2026, 1, 12));

    test('due in 2 days under a fixed clock: due-soon, not overdue', () {
      withClock(Clock.fixed(DateTime(2026, 1, 10)), () {
        expect(loan.isOverdue, isFalse);
        expect(loan.isDueSoon, isTrue);
      });
    });

    test('due in 10 days under a fixed clock: neither', () {
      withClock(Clock.fixed(DateTime(2026, 1, 2)), () {
        expect(loan.isOverdue, isFalse);
        expect(loan.isDueSoon, isFalse);
      });
    });

    test('past due under a fixed clock: overdue, not due-soon', () {
      withClock(Clock.fixed(DateTime(2026, 1, 13)), () {
        expect(loan.isOverdue, isTrue);
        expect(loan.isDueSoon, isFalse);
      });
    });

    test('returned loan is never overdue regardless of clock', () {
      final returned = _loan(
        expectedReturnDate: DateTime(2026, 1, 12),
        returnedAt: DateTime(2026, 1, 20),
      );
      withClock(Clock.fixed(DateTime(2026, 2, 1)), () {
        expect(returned.isOverdue, isFalse);
        expect(returned.isDueSoon, isFalse);
      });
    });
  });
}

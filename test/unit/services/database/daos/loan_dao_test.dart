import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  setUp(() => database = db_pkg.AppDatabase.memory());
  tearDown(() async => database.close());

  Future<void> seedItem({String id = 'item-1', String name = 'Camera'}) async {
    await database.itemDao.insertItem(
      db_pkg.ItemsCompanion.insert(
        id: id,
        name: name,
        categoryId:
            'cat-1', // required field — FK enforcement off in SQLite test mode
        roomId: 'room-1',
        createdAt: DateTime(2025),
        modifiedAt: DateTime(2025),
      ),
    );
  }

  Future<void> seedLoan({
    String id = 'loan-1',
    String itemId = 'item-1',
    String borrower = 'Alice',
    DateTime? returnedAt,
  }) async {
    await database.loanDao.insertLoan(
      db_pkg.LoansCompanion.insert(
        id: id,
        itemId: itemId,
        borrowerName: borrower,
        returnedAt: Value(returnedAt),
        createdAt: DateTime(2025),
        modifiedAt: DateTime(2025),
      ),
    );
  }

  test(
    'insertLoan + watchByItem — returns loan with itemName from join',
    () async {
      await seedItem();
      await seedLoan();
      final loans = await database.loanDao.watchByItem('item-1').first;
      expect(loans.length, 1);
      expect(loans.first.$1.borrowerName, 'Alice');
      expect(loans.first.$2, 'Camera'); // itemName from JOIN
    },
  );

  test('watchByItem — excludes soft-deleted loans', () async {
    await seedItem();
    await seedLoan();
    await database.loanDao.softDelete('loan-1');
    final loans = await database.loanDao.watchByItem('item-1').first;
    expect(loans, isEmpty);
  });

  test('watchActiveLoans — excludes returned loans', () async {
    await seedItem();
    await seedLoan(id: 'loan-1');
    await seedLoan(id: 'loan-2', returnedAt: DateTime(2025, 6));
    final active = await database.loanDao.watchActiveLoans().first;
    expect(active.length, 1);
    expect(active.first.$1.id, 'loan-1');
  });

  test('watchActiveLoanItemIds — returns set of item IDs', () async {
    await seedItem(id: 'item-1', name: 'Camera');
    await seedItem(id: 'item-2', name: 'Bike');
    await seedLoan(id: 'l1', itemId: 'item-1');
    await seedLoan(id: 'l2', itemId: 'item-2', returnedAt: DateTime(2025));
    final ids = await database.loanDao.watchActiveLoanItemIds().first;
    expect(ids, {'item-1'});
    expect(ids, isNot(contains('item-2')));
  });

  test('watchActiveLoans — excludes loans on soft-deleted items', () async {
    await seedItem();
    await seedLoan();
    // Soft-delete the item; the loan row remains active (no returnedAt).
    await database.itemDao.deleteItem('item-1');
    final active = await database.loanDao.watchActiveLoans().first;
    expect(active, isEmpty);
  });

  test(
    'watchActiveLoanItemIds — excludes loans on soft-deleted items',
    () async {
      await seedItem(id: 'item-1', name: 'Camera');
      await seedItem(id: 'item-2', name: 'Bike');
      await seedLoan(id: 'l1', itemId: 'item-1');
      await seedLoan(id: 'l2', itemId: 'item-2');
      await database.itemDao.deleteItem('item-2');
      final ids = await database.loanDao.watchActiveLoanItemIds().first;
      expect(ids, {'item-1'});
    },
  );

  test(
    'softDelete — sets isDeleted=true and removes from watchActiveLoans',
    () async {
      await seedItem();
      await seedLoan();
      await database.loanDao.softDelete('loan-1');
      final active = await database.loanDao.watchActiveLoans().first;
      expect(active, isEmpty);
    },
  );

  test('softDelete — stamps isDeleted=true and updates modifiedAt', () async {
    await seedItem();
    final before = DateTime(2025);
    await database.loanDao.insertLoan(
      db_pkg.LoansCompanion.insert(
        id: 'loan-del',
        itemId: 'item-1',
        borrowerName: 'Bob',
        returnedAt: const Value(null),
        createdAt: before,
        modifiedAt: before,
      ),
    );
    await database.loanDao.softDelete('loan-del');
    // Verify the row is soft-deleted
    final rows = await (database.select(
      database.loans,
    )..where((l) => l.id.equals('loan-del'))).get();
    expect(rows.length, 1);
    expect(rows.first.isDeleted, isTrue);
    // modifiedAt must have been updated from the seeded value (DateTime(2025))
    expect(rows.first.modifiedAt.isAfter(before), isTrue);
  });
}

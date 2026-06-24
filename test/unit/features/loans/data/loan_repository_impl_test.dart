import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/loans/data/repositories/loan_repository_impl.dart';
import 'package:still_life/features/loans/domain/entities/loan.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  late LoanRepositoryImpl repo;

  setUp(() {
    database = db_pkg.AppDatabase.memory();
    repo = LoanRepositoryImpl(database);
  });

  tearDown(() async => database.close());

  Future<void> seedItem({String id = 'item-1', String name = 'Camera'}) async {
    await database.itemDao.insertItem(
      db_pkg.ItemsCompanion.insert(
        id: id,
        name: name,
        categoryId: 'cat-1',
        roomId: 'room-1',
        createdAt: DateTime(2025),
        modifiedAt: DateTime(2025),
      ),
    );
  }

  test('createLoan — returns Loan with itemName populated', () async {
    await seedItem();
    final loan = Loan(
      id: '',
      itemId: 'item-1',
      itemName: 'Camera',
      borrowerName: 'Alice',
      createdAt: DateTime(2025),
      modifiedAt: DateTime(2025),
    );
    final result = await repo.createLoan(loan);
    result.when(
      success: (created) {
        expect(created.borrowerName, 'Alice');
        expect(created.itemName, 'Camera');
        expect(created.id, isNotEmpty);
      },
      failure: (f) => fail('Expected success, got $f'),
    );
  });

  test('markReturned — sets returnedAt', () async {
    await seedItem();
    final loan = Loan(
      id: 'l1',
      itemId: 'item-1',
      itemName: 'Camera',
      borrowerName: 'Bob',
      createdAt: DateTime(2025),
      modifiedAt: DateTime(2025),
    );
    await repo.createLoan(loan);
    final result = await repo.markReturned('l1');
    result.when(
      success: (_) {},
      failure: (f) => fail('Expected success, got $f'),
    );
    final loans = await repo.watchByItem('item-1').first;
    expect(loans.first.returnedAt, isNotNull);
  });

  test('editLoan — updates borrowerName', () async {
    await seedItem();
    final loan = Loan(
      id: 'l2',
      itemId: 'item-1',
      itemName: 'Camera',
      borrowerName: 'Carol',
      createdAt: DateTime(2025),
      modifiedAt: DateTime(2025),
    );
    await repo.createLoan(loan);
    final updated = loan.copyWith(borrowerName: 'Dave');
    final result = await repo.editLoan(updated);
    result.when(
      success: (edited) => expect(edited.borrowerName, 'Dave'),
      failure: (f) => fail('Expected success, got $f'),
    );
  });

  test('createLoan — returns error if item already on loan', () async {
    await seedItem();
    final loan1 = Loan(
      id: 'l-first',
      itemId: 'item-1',
      itemName: 'Camera',
      borrowerName: 'Alice',
      createdAt: DateTime(2025),
      modifiedAt: DateTime(2025),
    );
    final loan2 = Loan(
      id: 'l-second',
      itemId: 'item-1',
      itemName: 'Camera',
      borrowerName: 'Bob',
      createdAt: DateTime(2025),
      modifiedAt: DateTime(2025),
    );
    await repo.createLoan(loan1);
    final result = await repo.createLoan(loan2);
    result.when(
      success: (_) =>
          fail('Should have returned error for item already on loan'),
      failure: (f) => expect(f.toString(), contains('already on loan')),
    );
  });

  test('watchByItem — stream updates on insert', () async {
    await seedItem();
    final stream = repo.watchByItem('item-1');
    expect(await stream.first, isEmpty);
    final loan = Loan(
      id: 'l3',
      itemId: 'item-1',
      itemName: 'Camera',
      borrowerName: 'Eve',
      createdAt: DateTime(2025),
      modifiedAt: DateTime(2025),
    );
    await repo.createLoan(loan);
    expect(await stream.first, hasLength(1));
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/features/maintenance/data/repositories/maintenance_repository_impl.dart';
import 'package:still_life/features/maintenance/domain/entities/maintenance_log.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;

import '../../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;
  late MaintenanceRepositoryImpl repo;
  final now = DateTime(2025, 6, 1);
  final future = DateTime(2030, 1, 1);
  final past = DateTime(2020, 1, 1);

  setUp(() async {
    database = db_pkg.AppDatabase(NativeDatabase.memory());
    repo = MaintenanceRepositoryImpl(database);
  });

  tearDown(() => database.close());

  MaintenanceLog makeLog({
    String id = 'log1',
    String title = 'AC Filter',
    DateTime? performedAt,
    DateTime? nextDueAt,
    String? itemId,
  }) => MaintenanceLog(
    id: id,
    title: title,
    performedAt: performedAt ?? now,
    createdAt: now,
    modifiedAt: now,
    itemId: itemId,
    nextDueAt: nextDueAt,
  );

  group('MaintenanceRepositoryImpl', () {
    test('create and watchAll round-trip', () async {
      final log = makeLog();
      final result = await repo.create(log);
      expect(result, isA<Success<MaintenanceLog>>());
      expect((result as Success<MaintenanceLog>).value.title, 'AC Filter');

      final list = await repo.watchAll().first;
      expect(list, hasLength(1));
      expect(list.first.id, 'log1');
    });

    test('create assigns generated id when empty', () async {
      final log = makeLog(id: '');
      final result = await repo.create(log);
      expect(result, isA<Success<MaintenanceLog>>());
      final created = (result as Success<MaintenanceLog>).value;
      expect(created.id, isNotEmpty);
      expect(created.id, isNot(''));
    });

    test('update modifies fields', () async {
      await repo.create(makeLog());
      final updated = makeLog(title: 'HVAC Service');
      final result = await repo.update(updated);
      expect(result, isA<Success<MaintenanceLog>>());
      expect((result as Success<MaintenanceLog>).value.title, 'HVAC Service');
    });

    test('update returns Err for non-existent id', () async {
      final result = await repo.update(makeLog(id: 'ghost'));
      expect(result, isA<Err>());
    });

    test('delete removes log', () async {
      await repo.create(makeLog());
      final deleteResult = await repo.delete('log1');
      expect(deleteResult, isA<Success>());

      final list = await repo.watchAll().first;
      expect(list, isEmpty);
    });

    test('watchAll emits updated list reactively', () async {
      expect(await repo.watchAll().first, isEmpty);
      await repo.create(makeLog());
      expect(await repo.watchAll().first, hasLength(1));
    });

    test('watchByItem filters by itemId', () async {
      await repo.create(makeLog(id: 'log1', itemId: 'item1'));
      await repo.create(makeLog(id: 'log2', itemId: 'item2'));

      final results = await repo.watchByItem('item1').first;
      expect(results, hasLength(1));
      expect(results.first.id, 'log1');
    });

    test('getUpcoming returns only future nextDueAt', () async {
      await repo.create(makeLog(id: 'log1', nextDueAt: past, title: 'Past'));
      await repo.create(
        makeLog(id: 'log2', nextDueAt: future, title: 'Future'),
      );
      await repo.create(makeLog(id: 'log3', title: 'No Due'));

      final result = await repo.getUpcoming();
      expect(result, isA<Success<List<MaintenanceLog>>>());
      final list = (result as Success<List<MaintenanceLog>>).value;
      expect(list, hasLength(1));
      expect(list.first.title, 'Future');
    });
  });
}

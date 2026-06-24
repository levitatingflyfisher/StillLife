import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart';

import '../../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  final now = DateTime(2025, 6, 1);
  final future = DateTime(2030, 1, 1);
  final past = DateTime(2020, 1, 1);

  setUp(() async {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  MaintenanceLogsCompanion makeLog({
    String id = 'log1',
    String title = 'AC Filter',
    DateTime? performedAt,
    DateTime? nextDueAt,
    String? itemId,
  }) {
    return MaintenanceLogsCompanion.insert(
      id: id,
      title: title,
      performedAt: performedAt ?? now,
      createdAt: now,
      modifiedAt: now,
      itemId: Value(itemId),
      nextDueAt: Value(nextDueAt),
    );
  }

  group('MaintenanceDao', () {
    test('insertLog and getById', () async {
      await db.maintenanceDao.insertLog(makeLog());

      final result = await db.maintenanceDao.getById('log1');
      expect(result, isNotNull);
      expect(result!.id, 'log1');
      expect(result.title, 'AC Filter');
    });

    test('getById returns null for non-existent id', () async {
      final result = await db.maintenanceDao.getById('ghost');
      expect(result, isNull);
    });

    test('updateLog modifies title', () async {
      await db.maintenanceDao.insertLog(makeLog());
      final ok = await db.maintenanceDao.updateLog(
        const MaintenanceLogsCompanion(
          id: Value('log1'),
          title: Value('HVAC Service'),
          modifiedAt: Value.absent(),
        ),
      );
      expect(ok, isTrue);

      final result = await db.maintenanceDao.getById('log1');
      expect(result!.title, 'HVAC Service');
    });

    test('updateLog returns false for non-existent id', () async {
      final ok = await db.maintenanceDao.updateLog(
        const MaintenanceLogsCompanion(
          id: Value('ghost'),
          title: Value('Nope'),
        ),
      );
      expect(ok, isFalse);
    });

    test('deleteLog removes entry', () async {
      await db.maintenanceDao.insertLog(makeLog());
      final deleted = await db.maintenanceDao.deleteLog('log1');
      expect(deleted, 1);

      final result = await db.maintenanceDao.getById('log1');
      expect(result, isNull);
    });

    test('deleteLog returns 0 for non-existent id', () async {
      final deleted = await db.maintenanceDao.deleteLog('ghost');
      expect(deleted, 0);
    });

    test('watchAll orders by performedAt DESC', () async {
      await db.maintenanceDao.insertLog(
        makeLog(id: 'log1', title: 'Older', performedAt: past),
      );
      await db.maintenanceDao.insertLog(
        makeLog(id: 'log2', title: 'Newer', performedAt: future),
      );

      final results = await db.maintenanceDao.watchAll().first;
      expect(results, hasLength(2));
      expect(results.first.title, 'Newer');
      expect(results.last.title, 'Older');
    });

    test('watchByItem filters by itemId', () async {
      await db.maintenanceDao.insertLog(makeLog(id: 'log1', itemId: 'item1'));
      await db.maintenanceDao.insertLog(makeLog(id: 'log2', itemId: 'item2'));

      final results = await db.maintenanceDao.watchByItem('item1').first;
      expect(results, hasLength(1));
      expect(results.first.id, 'log1');
    });

    test('watchAll emits updated list reactively', () async {
      final initial = await db.maintenanceDao.watchAll().first;
      expect(initial, isEmpty);

      await db.maintenanceDao.insertLog(makeLog());
      final updated = await db.maintenanceDao.watchAll().first;
      expect(updated, hasLength(1));
    });

    test('getUpcoming returns only future nextDueAt', () async {
      // Past nextDueAt — should NOT appear
      await db.maintenanceDao.insertLog(
        makeLog(id: 'log1', title: 'Past Due', nextDueAt: past),
      );
      // Future nextDueAt — should appear
      await db.maintenanceDao.insertLog(
        makeLog(id: 'log2', title: 'Future Due', nextDueAt: future),
      );
      // No nextDueAt — should NOT appear
      await db.maintenanceDao.insertLog(makeLog(id: 'log3', title: 'No Due'));

      final results = await db.maintenanceDao.getUpcoming();
      expect(results, hasLength(1));
      expect(results.first.title, 'Future Due');
    });

    test('getUpcoming orders by nextDueAt ASC', () async {
      final near = DateTime.now().add(const Duration(days: 10));
      final far = DateTime.now().add(const Duration(days: 100));
      await db.maintenanceDao.insertLog(
        makeLog(id: 'log1', title: 'Far', nextDueAt: far),
      );
      await db.maintenanceDao.insertLog(
        makeLog(id: 'log2', title: 'Near', nextDueAt: near),
      );

      final results = await db.maintenanceDao.getUpcoming();
      expect(results.first.title, 'Near');
      expect(results.last.title, 'Far');
    });
  });
}

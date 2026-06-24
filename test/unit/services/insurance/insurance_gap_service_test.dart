import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;
import 'package:still_life/services/insurance/insurance_gap_service.dart';

import '../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase db;
  late InsuranceGapService svc;
  final now = DateTime(2025, 1, 1);

  setUp(() async {
    db = db_pkg.AppDatabase.memory();
    svc = InsuranceGapService(db);
    await db
        .into(db.properties)
        .insert(
          db_pkg.PropertiesCompanion.insert(
            id: 'p',
            name: 'Home',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          db_pkg.RoomsCompanion.insert(
            id: 'r',
            propertyId: 'p',
            name: 'Living',
            createdAt: now,
            modifiedAt: now,
          ),
        );
    await db
        .into(db.categories)
        .insert(
          db_pkg.CategoriesCompanion.insert(
            id: 'c',
            name: 'Cat',
            createdAt: now,
            modifiedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  Future<void> insertItem({
    required String id,
    double? currentValue,
    bool isInsured = false,
    bool isDeleted = false,
  }) => db
      .into(db.items)
      .insert(
        db_pkg.ItemsCompanion.insert(
          id: id,
          name: 'item $id',
          categoryId: 'c',
          roomId: 'r',
          currentValue: Value(currentValue),
          isInsured: Value(isInsured),
          isDeleted: Value(isDeleted),
          createdAt: now,
          modifiedAt: now,
        ),
      );

  test('returns uncovered items sorted by current_value DESC', () async {
    await insertItem(id: 'a', currentValue: 500);
    await insertItem(id: 'b', currentValue: 1500);
    await insertItem(id: 'c', currentValue: 800);
    final res = await svc.topUncovered(limit: 10);
    expect(res.map((i) => i.id), ['b', 'c', 'a']);
  });

  test('excludes insured items', () async {
    await insertItem(id: 'a', currentValue: 500);
    await insertItem(id: 'b', currentValue: 999, isInsured: true);
    final res = await svc.topUncovered();
    expect(res.map((i) => i.id), ['a']);
  });

  test('excludes soft-deleted items', () async {
    await insertItem(id: 'a', currentValue: 500);
    await insertItem(id: 'b', currentValue: 999, isDeleted: true);
    final res = await svc.topUncovered();
    expect(res.map((i) => i.id), ['a']);
  });

  test('excludes items with no currentValue', () async {
    await insertItem(id: 'a', currentValue: 500);
    await insertItem(id: 'b');
    final res = await svc.topUncovered();
    expect(res.map((i) => i.id), ['a']);
  });

  test('respects minValue filter', () async {
    await insertItem(id: 'a', currentValue: 100);
    await insertItem(id: 'b', currentValue: 700);
    final res = await svc.topUncovered(minValue: 500);
    expect(res.map((i) => i.id), ['b']);
  });

  test('respects limit', () async {
    await insertItem(id: 'a', currentValue: 100);
    await insertItem(id: 'b', currentValue: 200);
    await insertItem(id: 'c', currentValue: 300);
    final res = await svc.topUncovered(limit: 2);
    expect(res.length, 2);
    expect(res.map((i) => i.id), ['c', 'b']);
  });
}

import 'package:crdt/crdt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/constants/app_constants.dart';
import 'package:still_life/core/sync/seed_rows.dart';
import 'package:still_life/core/sync/sync_stamp.dart';
import 'package:still_life/features/inventory/data/repositories/category_repository_impl.dart';
import 'package:still_life/features/locations/data/repositories/room_repository_impl.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';
import 'package:still_life/services/import/import_fallback_seeder.dart';
import 'package:still_life/services/seeding/consumable_seeder.dart';
import 'package:still_life/services/sync/crdt_manager.dart';

import '../../../test_setup.dart';

class _Clock extends Mock implements CrdtManager {
  @override
  Future<String> getNodeId() async => 'node-a';

  @override
  Future<Hlc> nextHlc() async => Hlc(DateTime.utc(2030), 0, 'node-a');
}

class _MemStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _m = {};
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _m[key];
  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _m[key] = value;
  }
}

/// The decision: seeded defaults DO sync, as the same rows everywhere.
/// Each gets an id derived from what it is (not a random UUID) and a fixed
/// "seed" stamp older than any real edit. Two devices that seed separately
/// therefore hold identical rows that merge into one (a tie keeps local,
/// L5), and any real edit, stamped now, beats the seed on every device.
void main() {
  ensureSqlite3();

  Future<void> seedEverything(AppDatabase db) async {
    await CategoryRepositoryImpl(db).seedDefaults();
    final propertyId = await seedDefaultHome(db);
    await RoomRepositoryImpl(db).seedDefaults(propertyId);
    await ConsumableSeeder(database: db, storage: _MemStorage()).seedIfNeeded();
    await ImportFallbackSeeder(database: db).ensureDefaults();
  }

  Future<void> push(AppDatabase from, AppDatabase to) async {
    final json = await JsonExportService(from).exportToJson();
    // The stamps here are set in 2030; the receiver's clock is too, or the
    // future-stamp bound would (rightly) hold every row back.
    final r = await ImportService(to, clock: () => DateTime.utc(2031))
        .importFromJson(json, lww: true);
    expect(r.isSuccess, isTrue);
  }

  Future<List<String>> names(AppDatabase db, String table) async {
    final rows = await db
        .customSelect('SELECT name FROM $table WHERE is_deleted = 0')
        .get();
    return rows.map((r) => r.read<String>('name')).toList()..sort();
  }

  test('two devices that seed separately end with one set of defaults', () async {
    final a = AppDatabase.memory(), b = AppDatabase.memory();
    addTearDown(a.close);
    addTearDown(b.close);
    await seedEverything(a);
    await seedEverything(b);

    await push(a, b);
    await push(b, a);

    for (final t in ['categories', 'properties', 'rooms', 'items']) {
      final na = await names(a, t), nb = await names(b, t);
      expect(na, nb, reason: t);
      expect(na.toSet().length, na.length, reason: 'duplicate $t');
    }
    expect(
      (await names(a, 'categories')).toSet(),
      containsAll(AppConstants.defaultCategories),
    );
  });

  test('a rename of a default beats a later device\'s fresh seed', () async {
    final a = AppDatabase.memory(), b = AppDatabase.memory();
    addTearDown(a.close);
    addTearDown(b.close);
    await seedEverything(a);
    final repoA = CategoryRepositoryImpl(a, stamp: SyncStamp(_Clock()));
    final electronics = (await repoA.watchCategories().first).firstWhere(
      (c) => c.name == 'Electronics',
    );
    await repoA.updateCategory(electronics.copyWith(name: 'Gadgets'));

    await seedEverything(b); // B installs later and seeds afterwards

    await push(b, a); // B's fresh seed must not undo A's rename
    await push(a, b);

    for (final db in [a, b]) {
      final n = await names(db, 'categories');
      expect(n, contains('Gadgets'));
      expect(n, isNot(contains('Electronics')));
    }
  });

  test('seeded rows carry the fixed seed stamp', () async {
    final a = AppDatabase.memory();
    addTearDown(a.close);
    await seedEverything(a);
    final rows = await a
        .customSelect('SELECT hlc FROM categories UNION ALL SELECT hlc FROM rooms')
        .get();
    expect(rows.map((r) => r.read<String>('hlc')).toSet(), {seedHlc});
  });
}

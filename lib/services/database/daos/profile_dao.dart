import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  /// Streams all non-deleted profiles, ordered by name.
  Stream<List<Profile>> watchProfiles() {
    return (select(profiles)
          ..where((p) => p.isDeleted.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Future<Profile?> getProfile(String id) {
    return (select(profiles)
          ..where((p) => p.id.equals(id) & p.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<Profile?> getDefaultProfile() {
    return (select(profiles)
          ..where((p) => p.isDefault.equals(true) & p.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> insertProfile(
    ProfilesCompanion companion, {
    CrdtManager? crdt,
  }) async {
    final stamped = crdt != null
        ? companion.copyWith(
            nodeId: Value(await crdt.getNodeId()),
            hlc: Value((await crdt.nextHlc()).toString()),
          )
        : companion;
    await into(profiles).insert(stamped);
  }

  /// NEVER name this `update()` — Drift collision with DatabaseAccessor.
  Future<void> updateProfile(
    ProfilesCompanion companion, {
    CrdtManager? crdt,
  }) async {
    final stamped = crdt != null
        ? companion.copyWith(
            nodeId: Value(await crdt.getNodeId()),
            hlc: Value((await crdt.nextHlc()).toString()),
            modifiedAt: Value(DateTime.now()),
          )
        : companion.copyWith(modifiedAt: Value(DateTime.now()));
    await (update(profiles)..where(
          (p) => p.id.equals(stamped.id.value) & p.isDeleted.equals(false),
        ))
        .write(stamped);
  }

  /// Upsert (for sync import) — insertOnConflictUpdate.
  Future<void> upsertProfile(ProfilesCompanion companion) async {
    await into(profiles).insertOnConflictUpdate(companion);
  }

  Future<void> softDeleteProfile(String id, {CrdtManager? crdt}) async {
    final companion = crdt != null
        ? ProfilesCompanion(
            id: Value(id),
            isDeleted: const Value(true),
            modifiedAt: Value(DateTime.now()),
            nodeId: Value(await crdt.getNodeId()),
            hlc: Value((await crdt.nextHlc()).toString()),
          )
        : ProfilesCompanion(
            id: Value(id),
            isDeleted: const Value(true),
            modifiedAt: Value(DateTime.now()),
          );
    await (update(profiles)..where((p) => p.id.equals(id))).write(companion);
  }

  /// Clears the current default, sets [id] as the new default.
  /// Runs in a transaction to ensure atomicity.
  ///
  /// When [crdt] is provided, stamps `nodeId`/`hlc` on BOTH writes (the cleared
  /// previous default and the newly set default) so the CRDT merge engine can
  /// propagate the default-flag change to peers. Also bumps `modifiedAt` on
  /// both rows so the merge engine compares timestamps correctly.
  Future<void> setDefault(String id, {CrdtManager? crdt}) async {
    final now = DateTime.now();
    await transaction(() async {
      // Fetch previous defaults so each row can be stamped individually.
      final prevDefaults =
          await (select(profiles)..where(
                (p) => p.isDefault.equals(true) & p.isDeleted.equals(false),
              ))
              .get();
      for (final row in prevDefaults) {
        if (row.id == id) continue; // don't clear the one we're about to set
        var clear = ProfilesCompanion(
          id: Value(row.id),
          isDefault: const Value(false),
          modifiedAt: Value(now),
        );
        if (crdt != null) {
          final nodeId = await crdt.getNodeId();
          final hlc = await crdt.nextHlc();
          clear = clear.copyWith(
            nodeId: Value(nodeId),
            hlc: Value(hlc.toString()),
          );
        }
        await (update(
          profiles,
        )..where((p) => p.id.equals(row.id))).write(clear);
      }

      // Set the new default.
      var setNew = ProfilesCompanion(
        id: Value(id),
        isDefault: const Value(true),
        modifiedAt: Value(now),
      );
      if (crdt != null) {
        final nodeId = await crdt.getNodeId();
        final hlc = await crdt.nextHlc();
        setNew = setNew.copyWith(
          nodeId: Value(nodeId),
          hlc: Value(hlc.toString()),
        );
      }
      await (update(profiles)
            ..where((p) => p.id.equals(id) & p.isDeleted.equals(false)))
          .write(setNew);
    });
  }
}

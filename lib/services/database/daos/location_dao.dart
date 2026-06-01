import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'location_dao.g.dart';

@DriftAccessor(tables: [Properties, Rooms, Items])
class LocationDao extends DatabaseAccessor<AppDatabase>
    with _$LocationDaoMixin {
  LocationDao(super.db);

  // --- Properties ---

  Stream<List<Property>> watchAllProperties() {
    return (select(properties)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<Property?> getPropertyById(String id) {
    return (select(properties)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> insertProperty(
    PropertiesCompanion entry, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await into(properties).insert(entry);
  }

  Future<bool> updateProperty(
    PropertiesCompanion entry, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return (update(properties)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Soft-delete a property (and leaves rooms/items orphaned — they remain
  /// referencing a now-soft-deleted parent and are filtered by read-side queries).
  ///
  /// When [crdt] is provided, stamps `nodeId`/`hlc` on the tombstone write
  /// so the CRDT merge engine can propagate it to peers.
  Future<void> deleteProperty(String id, {CrdtManager? crdt}) async {
    var entry = PropertiesCompanion(
      id: Value(id),
      isDeleted: const Value(true),
      modifiedAt: Value(DateTime.now()),
    );
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await (update(properties)..where((t) => t.id.equals(id))).write(entry);
  }

  // --- Rooms ---

  Stream<List<Room>> watchAllRooms({String? propertyId}) {
    final query = select(rooms)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    if (propertyId != null) {
      query.where((t) => t.propertyId.equals(propertyId));
    }
    return query.watch();
  }

  Future<Room?> getRoomById(String id) {
    return (select(rooms)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> insertRoom(RoomsCompanion entry, {CrdtManager? crdt}) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await into(rooms).insert(entry);
  }

  Future<bool> updateRoom(RoomsCompanion entry, {CrdtManager? crdt}) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return (update(rooms)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Soft-delete a room (leaves items orphaned referencing the soft-deleted
  /// parent — read-side filters handle the exclusion).
  ///
  /// When [crdt] is provided, stamps `nodeId`/`hlc` on the tombstone write
  /// so the CRDT merge engine can propagate it to peers.
  Future<void> deleteRoom(String id, {CrdtManager? crdt}) async {
    var entry = RoomsCompanion(
      id: Value(id),
      isDeleted: const Value(true),
      modifiedAt: Value(DateTime.now()),
    );
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await (update(rooms)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> reorderRooms(List<String> roomIdsInOrder) async {
    await batch((batch) {
      for (var i = 0; i < roomIdsInOrder.length; i++) {
        batch.update(
          rooms,
          RoomsCompanion(sortOrder: Value(i)),
          where: (t) => t.id.equals(roomIdsInOrder[i]),
        );
      }
    });
  }

  /// Seed default rooms for a property.
  Future<void> seedDefaultRooms(
    String propertyId,
    List<RoomsCompanion> defaults,
  ) async {
    await batch((batch) {
      batch.insertAll(rooms, defaults);
    });
  }

  /// Get item count per room (excludes soft-deleted items).
  Future<Map<String, int>> getRoomItemCounts() async {
    final countExpr = items.id.count();
    final query = selectOnly(items)
      ..addColumns([items.roomId, countExpr])
      ..where(items.isDeleted.equals(false))
      ..groupBy([items.roomId]);
    final results = await query.get();
    return {
      for (final row in results)
        row.read(items.roomId)!: row.read(countExpr) ?? 0,
    };
  }

  /// Get value per room (excludes soft-deleted items).
  Future<Map<String, double>> getRoomValues() async {
    final sumExpr = items.currentValue.sum();
    final query = selectOnly(items)
      ..addColumns([items.roomId, sumExpr])
      ..where(items.isDeleted.equals(false))
      ..groupBy([items.roomId]);
    final results = await query.get();
    return {
      for (final row in results)
        row.read(items.roomId)!: row.read(sumExpr) ?? 0.0,
    };
  }
}

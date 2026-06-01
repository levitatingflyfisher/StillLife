import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../../sync/crdt_manager.dart';

part 'container_dao.g.dart';

@DriftAccessor(tables: [StorageContainers])
class ContainerDao extends DatabaseAccessor<AppDatabase>
    with _$ContainerDaoMixin {
  ContainerDao(super.db);

  Stream<List<StorageContainer>> watchByRoom(String roomId) {
    return (select(storageContainers)
          ..where((t) => t.roomId.equals(roomId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<StorageContainer>> watchAll() {
    return (select(storageContainers)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  Future<StorageContainer?> getById(String id) {
    return (select(storageContainers)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> insert(
    StorageContainersCompanion entry, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await into(storageContainers).insert(entry);
  }

  Future<bool> updateContainer(
    StorageContainersCompanion entry, {
    CrdtManager? crdt,
  }) async {
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    return (update(storageContainers)
          ..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  Future<void> softDelete(String id, {CrdtManager? crdt}) async {
    var entry = StorageContainersCompanion(
      id: Value(id),
      isDeleted: const Value(true),
      modifiedAt: Value(DateTime.now()),
    );
    if (crdt != null) {
      final nodeId = await crdt.getNodeId();
      final hlc = await crdt.nextHlc();
      entry = entry.copyWith(nodeId: Value(nodeId), hlc: Value(hlc.toString()));
    }
    await (update(
      storageContainers,
    )..where((t) => t.id.equals(id))).write(entry);
  }
}

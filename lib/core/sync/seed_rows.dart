import 'package:crdt/crdt.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../services/database/database.dart';

/// How seeded defaults sync (the default categories, the first home and its
/// rooms, the consumables starter kit, the import fallbacks).
///
/// They DO sync, as the same rows on every device:
/// - **Id from what the row is**, not a random UUID ([seedId]). Two devices
///   that seed separately create the same "Electronics", so a sync merges
///   them into one instead of showing two.
/// - **A fixed stamp older than any real edit** ([seedHlc]). Two seeds tie,
///   and a tie keeps the local row (yellow paper L5), so identical defaults
///   never fight. Any real edit is stamped now, so it beats the seed on
///   every device, including one that installs and seeds a month later.
///
/// Rows seeded before this existed have random ids and no stamp; they are
/// left as they are (re-keying them would break every item that points at
/// them). Two such devices still show two sets of defaults after a sync.
const seedNodeId = 'seed';

/// Older than any real stamp, and non-empty so it is never blind-applied.
final String seedHlc = Hlc(DateTime.utc(2000), 0, seedNodeId).toString();

/// A stable id for a seeded row: the same [kind] and [key] give the same
/// id on every device.
String seedId(String kind, String key) =>
    const Uuid().v5(Namespace.url.value, 'stilllife:seed:$kind:$key');

const String defaultHomeName = 'My Home';

/// Creates the first home (if there is none) under its seed id and stamp,
/// and returns the id of the home to seed rooms into.
Future<String> seedDefaultHome(AppDatabase db) async {
  final existing =
      await (db.select(db.properties)
            ..where((p) => p.isDeleted.equals(false))
            ..limit(1))
          .getSingleOrNull();
  if (existing != null) return existing.id;
  final id = seedId('property', defaultHomeName);
  final now = DateTime.now();
  await db
      .into(db.properties)
      .insert(
        PropertiesCompanion.insert(
          id: id,
          name: defaultHomeName,
          type: const Value('Home'),
          createdAt: now,
          modifiedAt: now,
          nodeId: const Value(seedNodeId),
          hlc: Value(seedHlc),
        ),
        mode: InsertMode.insertOrIgnore,
      );
  return id;
}

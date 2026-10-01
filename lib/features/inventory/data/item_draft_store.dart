import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../services/database/database.dart';

/// Unsaved Add Item work, written as it is typed so leaving by any route
/// (back, a tab, the app killed in the background) loses nothing. Kept in
/// the device-local `item_drafts` table: never synced, never exported.
class ItemDraftStore {
  ItemDraftStore(this._db);
  final AppDatabase _db;

  Future<Map<String, Object?>?> read(String key) async {
    final row = await (_db.select(_db.itemDrafts)
          ..where((d) => d.key.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      return (jsonDecode(row.data) as Map).cast<String, Object?>();
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String key, Map<String, Object?> draft) =>
      _db.into(_db.itemDrafts).insertOnConflictUpdate(
            ItemDraftsCompanion.insert(
              key: key,
              data: jsonEncode(draft),
              updatedAt: DateTime.now(),
            ),
          );

  Future<void> clear(String key) =>
      (_db.delete(_db.itemDrafts)..where((d) => d.key.equals(key))).go();
}

final itemDraftStoreProvider =
    Provider<ItemDraftStore>((ref) => ItemDraftStore(ref.watch(databaseProvider)));

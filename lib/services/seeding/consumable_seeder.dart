import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

const _kSeededKey = 'consumables_seeded_v1';
const _uuid = Uuid();

/// Seeds a "Consumables" category and five starter items exactly once.
///
/// Seeding is guarded by [_kSeededKey] in FlutterSecureStorage.
/// Items are only seeded if at least one room already exists.
class ConsumableSeeder {
  final AppDatabase _database;
  final FlutterSecureStorage _storage;

  ConsumableSeeder({
    required AppDatabase database,
    FlutterSecureStorage? storage,
  }) : _database = database,
       _storage = storage ?? const FlutterSecureStorage();

  Future<void> seedIfNeeded() async {
    final alreadySeeded = await _storage.read(key: _kSeededKey);
    if (alreadySeeded != null) return;

    final now = DateTime.now();
    final categoryId = _uuid.v4();

    // Create the "Consumables" category (ignore if name already exists).
    await _database
        .into(_database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: categoryId,
            name: 'Consumables',
            createdAt: now,
            modifiedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // Only seed items if at least one room exists.
    final rooms = await _database.select(_database.rooms).get();
    if (rooms.isNotEmpty) {
      final roomId = rooms.first.id;
      for (final t in _kTemplates) {
        await _database.itemDao.insertItem(
          ItemsCompanion.insert(
            id: _uuid.v4(),
            name: t.name,
            categoryId: categoryId,
            roomId: roomId,
            quantity: Value(t.quantity),
            quantityUnit: Value(t.unit),
            lowStockThreshold: Value(t.threshold),
            createdAt: now,
            modifiedAt: now,
          ),
        );
      }
    }

    await _storage.write(key: _kSeededKey, value: 'done');
  }
}

class _Template {
  final String name;
  final double quantity;
  final String unit;
  final double threshold;
  const _Template(
    this.name, {
    required this.quantity,
    required this.unit,
    required this.threshold,
  });
}

const _kTemplates = [
  _Template('Paper Towels', quantity: 6, unit: 'rolls', threshold: 2),
  _Template('Dish Soap', quantity: 2, unit: 'bottles', threshold: 1),
  _Template('Coffee Beans', quantity: 500, unit: 'g', threshold: 100),
  _Template('Toilet Paper', quantity: 12, unit: 'rolls', threshold: 4),
  _Template('Hand Soap', quantity: 3, unit: 'pumps', threshold: 1),
];

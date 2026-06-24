# Phase 16 — Natural Language Search + Smart Filters

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let users type "expensive stuff in the garage" or "where is my camera" and get precise, filtered results — all offline, no LLM required for the common case.

**Architecture:** A pure-Dart `NlQueryParser` (rules + keyword matching) converts free text to an `ItemQuery`. A `SavedSearchService` stores bookmarked queries in `FlutterSecureStorage`. `SearchScreen` gains NL routing, a "where is my" result card, and a saved-search chip row. `FilterDialog` gains presence chips (has photo/receipt/barcode) and date pickers. Both `SearchScreen` and `InventoryScreen` search bars route through the parser silently.

**Tech Stack:** Flutter, Riverpod, Drift ORM, GoRouter, FlutterSecureStorage, `flutter_secure_storage: ^9.2.4`

---

### Task 1: Extend ItemQuery and FilterResult with presence + date fields

**Files:**
- Modify: `lib/features/inventory/domain/repositories/item_repository.dart`
- Modify: `lib/features/inventory/presentation/widgets/filter_dialog.dart`
- Test: `test/unit/features/inventory/domain/repositories/item_query_test.dart` (new)

**Step 1: Write the failing test**

Create `test/unit/features/inventory/domain/repositories/item_query_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/inventory/presentation/widgets/filter_dialog.dart';

void main() {
  group('FilterResult.applyTo', () {
    test('passes hasPhoto through to ItemQuery', () {
      const filter = FilterResult(hasPhoto: true);
      final q = filter.applyTo(const ItemQuery());
      expect(q.hasPhoto, isTrue);
    });

    test('passes hasReceipt through to ItemQuery', () {
      const filter = FilterResult(hasReceipt: true);
      final q = filter.applyTo(const ItemQuery());
      expect(q.hasReceipt, isTrue);
    });

    test('passes hasBarcode through to ItemQuery', () {
      const filter = FilterResult(hasBarcode: true);
      final q = filter.applyTo(const ItemQuery());
      expect(q.hasBarcode, isTrue);
    });

    test('passes addedAfter/addedBefore through', () {
      final after = DateTime(2025, 1, 1);
      final before = DateTime(2025, 12, 31);
      final filter = FilterResult(addedAfter: after, addedBefore: before);
      final q = filter.applyTo(const ItemQuery());
      expect(q.addedAfter, equals(after));
      expect(q.addedBefore, equals(before));
    });

    test('isActive is true when hasPhoto set', () {
      expect(const FilterResult(hasPhoto: true).isActive, isTrue);
    });

    test('activeFilterCount counts presence flags', () {
      const f = FilterResult(hasPhoto: true, hasReceipt: true);
      expect(f.activeFilterCount, equals(2));
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/unit/features/inventory/domain/repositories/item_query_test.dart
```

Expected: FAIL — `FilterResult` and `ItemQuery` have no `hasPhoto` / `hasReceipt` / `hasBarcode` / `addedAfter` / `addedBefore` fields.

**Step 3: Add fields to ItemQuery**

In `lib/features/inventory/domain/repositories/item_repository.dart`, add after `final DateTime? addedBefore;`:

```dart
  final bool? hasPhoto;
  final bool? hasReceipt;
  final bool? hasBarcode;
```

Add to `const ItemQuery({...})` constructor:

```dart
    this.hasPhoto,
    this.hasReceipt,
    this.hasBarcode,
```

**Step 4: Add fields to FilterResult**

In `lib/features/inventory/presentation/widgets/filter_dialog.dart`, add to `FilterResult`:

```dart
  final bool? hasPhoto;
  final bool? hasReceipt;
  final bool? hasBarcode;
  final DateTime? addedAfter;
  final DateTime? addedBefore;
```

Add to `const FilterResult({...})` constructor:

```dart
    this.hasPhoto,
    this.hasReceipt,
    this.hasBarcode,
    this.addedAfter,
    this.addedBefore,
```

Update `isActive`:

```dart
  bool get isActive =>
      roomId != null ||
      categoryId != null ||
      (tagIds != null && tagIds!.isNotEmpty) ||
      condition != null ||
      minValue != null ||
      maxValue != null ||
      hasPhoto != null ||
      hasReceipt != null ||
      hasBarcode != null ||
      addedAfter != null ||
      addedBefore != null;
```

Update `activeFilterCount`:

```dart
    if (hasPhoto != null) count++;
    if (hasReceipt != null) count++;
    if (hasBarcode != null) count++;
    if (addedAfter != null || addedBefore != null) count++;
```

Update `applyTo`:

```dart
  ItemQuery applyTo(ItemQuery query) {
    return ItemQuery(
      searchText: query.searchText,
      roomId: roomId,
      categoryId: categoryId,
      tagIds: tagIds,
      condition: condition,
      minValue: minValue,
      maxValue: maxValue,
      priceField: priceField,
      addedAfter: addedAfter,
      addedBefore: addedBefore,
      hasPhoto: hasPhoto,
      hasReceipt: hasReceipt,
      hasBarcode: hasBarcode,
      sortBy: query.sortBy,
      ascending: query.ascending,
    );
  }
```

**Step 5: Run test to verify it passes**

```bash
flutter test test/unit/features/inventory/domain/repositories/item_query_test.dart
```

Expected: PASS (6 tests)

**Step 6: Run full suite to check for regressions**

```bash
flutter test
```

Expected: all 377 previously-passing tests still pass.

**Step 7: Commit**

```bash
git add lib/features/inventory/domain/repositories/item_repository.dart \
        lib/features/inventory/presentation/widgets/filter_dialog.dart \
        test/unit/features/inventory/domain/repositories/item_query_test.dart
git commit -m "feat: ItemQuery + FilterResult gain hasPhoto/hasReceipt/hasBarcode + date-range fields"
```

---

### Task 2: ItemDao — presence filter WHERE clauses

**Files:**
- Modify: `lib/services/database/daos/item_dao.dart`
- Test: `test/unit/services/database/daos/item_dao_presence_test.dart` (new)

**Step 1: Write the failing test**

Create `test/unit/services/database/daos/item_dao_presence_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart' as db_pkg;

import '../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late db_pkg.AppDatabase database;

  setUp(() {
    database = db_pkg.AppDatabase.forTesting();
  });

  tearDown(() => database.close());

  Future<String> insertItem(String name, {String? barcode}) async {
    const roomId = 'room-1';
    const catId = 'cat-1';
    // Ensure room + category exist
    await database.into(database.rooms).insertOnConflictUpdate(
      db_pkg.RoomsCompanion.insert(
        id: 'room-1', propertyId: 'prop-1', name: 'Room',
        sortOrder: const Value(0), createdAt: DateTime.now(), modifiedAt: DateTime.now(),
      ),
    );
    await database.into(database.categories).insertOnConflictUpdate(
      db_pkg.CategoriesCompanion.insert(
        id: 'cat-1', name: 'Cat',
        createdAt: DateTime.now(), modifiedAt: DateTime.now(),
      ),
    );
    final id = 'item-${name.toLowerCase().replaceAll(' ', '-')}';
    await database.itemDao.insertItem(
      db_pkg.ItemsCompanion.insert(
        id: id, name: name, description: const Value(''),
        categoryId: catId, roomId: roomId,
        barcode: Value(barcode),
        createdAt: DateTime.now(), modifiedAt: DateTime.now(),
      ),
    );
    return id;
  }

  group('ItemDao presence filters', () {
    test('hasPhoto=true returns only items with photos', () async {
      final idWith = await insertItem('With Photo');
      await insertItem('No Photo');

      await database.into(database.photos).insert(
        db_pkg.PhotosCompanion.insert(
          id: 'photo-1', itemId: idWith, path: '/p.jpg',
          createdAt: DateTime.now(), modifiedAt: DateTime.now(),
        ),
      );

      final results = await database.itemDao
          .watchAllItems(hasPhoto: true)
          .first;
      expect(results.map((r) => r.name), contains('With Photo'));
      expect(results.map((r) => r.name), isNot(contains('No Photo')));
    });

    test('hasBarcode=true excludes items with null or empty barcode', () async {
      await insertItem('Barcoded', barcode: '012345678905');
      await insertItem('No Barcode');
      await insertItem('Empty Barcode', barcode: '');

      final results = await database.itemDao
          .watchAllItems(hasBarcode: true)
          .first;
      expect(results.map((r) => r.name), contains('Barcoded'));
      expect(results.map((r) => r.name), isNot(contains('No Barcode')));
      expect(results.map((r) => r.name), isNot(contains('Empty Barcode')));
    });

    test('hasReceipt=true returns only items with receipts', () async {
      final idWith = await insertItem('With Receipt');
      await insertItem('No Receipt');

      await database.into(database.receipts).insert(
        db_pkg.ReceiptsCompanion.insert(
          id: 'rcpt-1', itemId: const Value(''),
          photoPath: '/r.jpg',
          createdAt: DateTime.now(),
        ).copyWith(itemId: Value(idWith)),
      );

      final results = await database.itemDao
          .watchAllItems(hasReceipt: true)
          .first;
      expect(results.map((r) => r.name), contains('With Receipt'));
      expect(results.map((r) => r.name), isNot(contains('No Receipt')));
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/unit/services/database/daos/item_dao_presence_test.dart
```

Expected: FAIL — `watchAllItems` has no `hasPhoto`, `hasBarcode`, `hasReceipt` params.

**Step 3: Add params to ItemDao**

In `lib/services/database/daos/item_dao.dart`, update the `@DriftAccessor` annotation to include `Receipts`:

```dart
@DriftAccessor(tables: [Items, Categories, Rooms, Photos, ItemTags, Tags, Receipts])
```

Add parameters to `watchAllItems()` signature after `addedBefore`:

```dart
  bool? hasPhoto,
  bool? hasReceipt,
  bool? hasBarcode,
```

Add WHERE clauses after the `addedBefore` block (before the sorting section):

```dart
    if (hasPhoto == true) {
      query.where((t) => customExpression<bool>(
        'EXISTS (SELECT 1 FROM photos WHERE photos.item_id = items.id AND photos.is_deleted = 0)',
      ));
    }
    if (hasReceipt == true) {
      query.where((t) => customExpression<bool>(
        'EXISTS (SELECT 1 FROM receipts WHERE receipts.item_id = items.id AND receipts.is_deleted = 0)',
      ));
    }
    if (hasBarcode == true) {
      query.where((t) => t.barcode.isNotNull() & t.barcode.isNotValue(''));
    }
```

**Step 4: Regenerate Drift code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: exits 0, regenerates `item_dao.g.dart`.

**Step 5: Run test to verify it passes**

```bash
flutter test test/unit/services/database/daos/item_dao_presence_test.dart
```

Expected: PASS (3 tests). If the `ReceiptsCompanion` constructor differs, adjust accordingly.

**Step 6: Run full suite**

```bash
flutter test
```

Expected: 383+ tests pass.

**Step 7: Commit**

```bash
git add lib/services/database/daos/item_dao.dart \
        lib/services/database/daos/item_dao.g.dart \
        test/unit/services/database/daos/item_dao_presence_test.dart
git commit -m "feat: ItemDao watchAllItems gains hasPhoto/hasReceipt/hasBarcode WHERE clauses"
```

---

### Task 3: Pass presence fields through ItemRepositoryImpl

**Files:**
- Modify: `lib/features/inventory/data/repositories/item_repository_impl.dart`

**Step 1: Update watchItems() call**

In `ItemRepositoryImpl.watchItems()`, add three new params to the `watchAllItems()` call:

```dart
    return _db.itemDao
        .watchAllItems(
          roomId: query.roomId,
          categoryId: query.categoryId,
          containerId: query.containerId,
          condition: query.condition?.label,
          minValue: query.minValue,
          maxValue: query.maxValue,
          priceField: query.priceField.name,
          addedAfter: query.addedAfter,
          addedBefore: query.addedBefore,
          hasPhoto: query.hasPhoto,
          hasReceipt: query.hasReceipt,
          hasBarcode: query.hasBarcode,
          sortBy: query.sortBy.name,
          ascending: query.ascending,
          limit: query.limit,
          offset: query.offset,
        )
        .map((rows) => rows.map(_mapToEntity).toList());
```

**Step 2: Run full suite**

```bash
flutter test
```

Expected: all tests pass (no new tests needed — the DAO test from Task 2 covers this path indirectly).

**Step 3: Commit**

```bash
git add lib/features/inventory/data/repositories/item_repository_impl.dart
git commit -m "feat: ItemRepositoryImpl passes hasPhoto/hasReceipt/hasBarcode to ItemDao"
```

---

### Task 4: ContainerDao watchAll + allContainersProvider

**Files:**
- Modify: `lib/services/database/daos/container_dao.dart`
- Modify: `lib/features/locations/domain/repositories/container_repository.dart`
- Modify: `lib/features/locations/data/repositories/container_repository_impl.dart`
- Modify: `lib/features/locations/presentation/controllers/location_controller.dart`

The NL parser needs all containers across all rooms to do name-matching. `containersInRoomProvider` is per-room; we need an `allContainersProvider`.

**Step 1: Add watchAll() to ContainerDao**

In `lib/services/database/daos/container_dao.dart`, add after `watchByRoom`:

```dart
  Stream<List<StorageContainer>> watchAll() {
    return (select(storageContainers)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }
```

**Step 2: Add watchAllContainers() to ContainerRepository interface**

In `lib/features/locations/domain/repositories/container_repository.dart`, add:

```dart
  Stream<List<StorageContainer>> watchAllContainers();
```

**Step 3: Implement in ContainerRepositoryImpl**

In `lib/features/locations/data/repositories/container_repository_impl.dart`, add:

```dart
  @override
  Stream<List<StorageContainer>> watchAllContainers() {
    return _db.containerDao.watchAll().map((rows) => rows.map(_map).toList());
  }
```

**Step 4: Add allContainersProvider**

In `lib/features/locations/presentation/controllers/location_controller.dart`, add after `containersInRoomProvider`:

```dart
final allContainersProvider = StreamProvider<List<StorageContainer>>((ref) {
  return ref.watch(containerRepositoryProvider).watchAllContainers();
});
```

**Step 5: Run full suite**

```bash
flutter test
```

Expected: all tests pass (no new tests — this is a thin pass-through; covered by widget tests later).

**Step 6: Commit**

```bash
git add lib/services/database/daos/container_dao.dart \
        lib/features/locations/domain/repositories/container_repository.dart \
        lib/features/locations/data/repositories/container_repository_impl.dart \
        lib/features/locations/presentation/controllers/location_controller.dart
git commit -m "feat: ContainerDao.watchAll + allContainersProvider for NL parser"
```

---

### Task 5: NlQueryParser — pure Dart, fully tested

**Files:**
- Create: `lib/features/search/domain/services/nl_query_parser.dart`
- Test: `test/unit/features/search/services/nl_query_parser_test.dart` (new)

**Step 1: Write the failing tests first**

Create `test/unit/features/search/services/nl_query_parser_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/locations/domain/entities/room.dart';
import 'package:still_life/features/locations/domain/entities/storage_container.dart';
import 'package:still_life/features/inventory/domain/entities/category.dart';
import 'package:still_life/features/search/domain/services/nl_query_parser.dart';

Room _room(String id, String name) => Room(
      id: id, propertyId: 'p', name: name,
      sortOrder: 0, createdAt: DateTime(2025), modifiedAt: DateTime(2025),
    );

Category _cat(String id, String name) => Category(
      id: id, name: name, iconName: null, color: null,
      createdAt: DateTime(2025), modifiedAt: DateTime(2025),
    );

StorageContainer _cont(String id, String roomId, String name) => StorageContainer(
      id: id, roomId: roomId, name: name,
      createdAt: DateTime(2025), modifiedAt: DateTime(2025),
    );

NlQueryParser _parser({
  List<Room>? rooms,
  List<Category>? categories,
  List<StorageContainer>? containers,
}) =>
    NlQueryParser(
      rooms: rooms ?? [],
      categories: categories ?? [],
      containers: containers ?? [],
    );

void main() {
  group('NlQueryParser — price keywords', () {
    test('extracts minValue from "over \$200"', () {
      final r = _parser().parse('stuff over \$200');
      expect(r.query.minValue, equals(200.0));
    });

    test('extracts maxValue from "under \$50"', () {
      final r = _parser().parse('things under \$50');
      expect(r.query.maxValue, equals(50.0));
    });

    test('"expensive" sets minValue=500', () {
      final r = _parser().parse('expensive electronics');
      expect(r.query.minValue, equals(500.0));
      expect(r.residualText.trim(), equals('electronics'));
    });

    test('"cheap" sets maxValue=100', () {
      final r = _parser().parse('cheap stuff');
      expect(r.query.maxValue, equals(100.0));
    });
  });

  group('NlQueryParser — room matching', () {
    final rooms = [_room('g1', 'Garage'), _room('lr', 'Living Room')];

    test('extracts roomId from room name in query', () {
      final r = _parser(rooms: rooms).parse('tools in the garage');
      expect(r.query.roomId, equals('g1'));
      expect(r.hasStructuredFilters, isTrue);
    });

    test('is case-insensitive', () {
      final r = _parser(rooms: rooms).parse('stuff in LIVING ROOM');
      expect(r.query.roomId, equals('lr'));
    });

    test('residualText strips room name', () {
      final r = _parser(rooms: rooms).parse('expensive stuff in the garage');
      expect(r.residualText, isNot(contains('garage')));
    });
  });

  group('NlQueryParser — category matching', () {
    final cats = [_cat('el', 'Electronics'), _cat('furn', 'Furniture')];

    test('extracts categoryId from category name', () {
      final r = _parser(categories: cats).parse('electronics over \$100');
      expect(r.query.categoryId, equals('el'));
    });
  });

  group('NlQueryParser — date keywords', () {
    test('"recent" sets addedAfter ~30 days ago', () {
      final r = _parser().parse('recent purchases');
      expect(r.query.addedAfter, isNotNull);
      final age = DateTime.now().difference(r.query.addedAfter!).inDays;
      expect(age, closeTo(30, 2));
    });

    test('"this year" sets addedAfter to Jan 1 of current year', () {
      final r = _parser().parse('items added this year');
      expect(r.query.addedAfter?.year, equals(DateTime.now().year));
      expect(r.query.addedAfter?.month, equals(1));
    });
  });

  group('NlQueryParser — presence flags', () {
    test('"with photo" sets hasPhoto=true', () {
      final r = _parser().parse('items with photo');
      expect(r.query.hasPhoto, isTrue);
    });

    test('"has receipt" sets hasReceipt=true', () {
      final r = _parser().parse('stuff has receipt');
      expect(r.query.hasReceipt, isTrue);
    });

    test('"with barcode" sets hasBarcode=true', () {
      final r = _parser().parse('with barcode');
      expect(r.query.hasBarcode, isTrue);
    });
  });

  group('NlQueryParser — sort keywords', () {
    test('"most valuable" sets sortBy=currentValue descending', () {
      final r = _parser().parse('most valuable items');
      expect(r.query.sortBy, equals(ItemSortField.currentValue));
      expect(r.query.ascending, isFalse);
    });

    test('"newest" sets sortBy=createdAt descending', () {
      final r = _parser().parse('newest items');
      expect(r.query.sortBy, equals(ItemSortField.createdAt));
      expect(r.query.ascending, isFalse);
    });
  });

  group('NlQueryParser — where-is mode', () {
    test('"where is my X" strips prefix, isWhereIs=true', () {
      final r = _parser().parse('where is my camera');
      expect(r.isWhereIs, isTrue);
      expect(r.residualText.trim(), equals('camera'));
    });

    test('"find my X" strips prefix', () {
      final r = _parser().parse('find my laptop');
      expect(r.isWhereIs, isTrue);
      expect(r.residualText.trim(), equals('laptop'));
    });
  });

  group('NlQueryParser — edge cases', () {
    test('empty input returns empty ItemQuery', () {
      final r = _parser().parse('');
      expect(r.hasStructuredFilters, isFalse);
      expect(r.residualText, isEmpty);
      expect(r.needsLlmFallback, isFalse);
    });

    test('short gibberish does not set needsLlmFallback', () {
      final r = _parser().parse('xy');
      expect(r.needsLlmFallback, isFalse);
    });

    test('unrecognised text sets needsLlmFallback', () {
      final r = _parser().parse('whatchamacallit thingy');
      expect(r.needsLlmFallback, isTrue);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/unit/features/search/services/nl_query_parser_test.dart
```

Expected: FAIL — file does not exist yet.

**Step 3: Create NlQueryParser**

Create `lib/features/search/domain/services/nl_query_parser.dart`:

```dart
import '../../../inventory/domain/entities/category.dart';
import '../../../inventory/domain/repositories/item_repository.dart';
import '../../../locations/domain/entities/room.dart';
import '../../../locations/domain/entities/storage_container.dart';

class ParseResult {
  final ItemQuery query;
  final bool hasStructuredFilters;
  final String residualText;
  final bool isWhereIs;
  final bool needsLlmFallback;

  const ParseResult({
    required this.query,
    required this.hasStructuredFilters,
    required this.residualText,
    required this.isWhereIs,
    required this.needsLlmFallback,
  });
}

class NlQueryParser {
  final List<Room> rooms;
  final List<Category> categories;
  final List<StorageContainer> containers;

  const NlQueryParser({
    required this.rooms,
    required this.categories,
    required this.containers,
  });

  static final _whereIsRe =
      RegExp(r"^(where\s+is|find\s+my|where'?s)\s+(?:my|the|a|an)?\s*",
          caseSensitive: false);
  static final _overRe =
      RegExp(r'\b(?:over|more\s+than|above)\s+\$?(\d+(?:\.\d+)?)\b',
          caseSensitive: false);
  static final _underRe =
      RegExp(r'\b(?:under|less\s+than|below)\s+\$?(\d+(?:\.\d+)?)\b',
          caseSensitive: false);
  static final _expensiveRe =
      RegExp(r'\b(expensive|valuable)\b', caseSensitive: false);
  static final _cheapRe =
      RegExp(r'\b(cheap|inexpensive)\b', caseSensitive: false);
  static final _recentRe =
      RegExp(r'\b(recent|recently|last\s+month)\b', caseSensitive: false);
  static final _thisYearRe =
      RegExp(r'\bthis\s+year\b', caseSensitive: false);
  static final _withPhotoRe =
      RegExp(r'\b(with\s+photo|has\s+photo)\b', caseSensitive: false);
  static final _withReceiptRe =
      RegExp(r'\b(with\s+receipt|has\s+receipt)\b', caseSensitive: false);
  static final _withBarcodeRe =
      RegExp(r'\b(with\s+barcode|has\s+barcode)\b', caseSensitive: false);
  static final _mostValuableRe =
      RegExp(r'\b(most\s+valuable|by\s+value)\b', caseSensitive: false);
  static final _newestRe =
      RegExp(r'\b(newest|recently\s+added)\b', caseSensitive: false);

  ParseResult parse(String input) {
    if (input.trim().isEmpty) {
      return const ParseResult(
        query: ItemQuery(),
        hasStructuredFilters: false,
        residualText: '',
        isWhereIs: false,
        needsLlmFallback: false,
      );
    }

    var text = input.trim();
    final isWhereIs = _whereIsRe.hasMatch(text);
    text = text.replaceFirst(_whereIsRe, '');

    String? roomId;
    String? categoryId;
    String? containerId;
    double? minValue;
    double? maxValue;
    DateTime? addedAfter;
    bool? hasPhoto;
    bool? hasReceipt;
    bool? hasBarcode;
    ItemSortField sortBy = ItemSortField.name;
    bool ascending = true;

    // Sort keywords (check before stripping other tokens)
    if (_mostValuableRe.hasMatch(text)) {
      sortBy = ItemSortField.currentValue;
      ascending = false;
      text = text.replaceAll(_mostValuableRe, '');
    }
    if (_newestRe.hasMatch(text)) {
      sortBy = ItemSortField.createdAt;
      ascending = false;
      text = text.replaceAll(_newestRe, '');
    }

    // Price range
    final overMatch = _overRe.firstMatch(text);
    if (overMatch != null) {
      minValue = double.tryParse(overMatch.group(1)!);
      text = text.replaceAll(_overRe, '');
    }
    final underMatch = _underRe.firstMatch(text);
    if (underMatch != null) {
      maxValue = double.tryParse(underMatch.group(1)!);
      text = text.replaceAll(_underRe, '');
    }
    if (_expensiveRe.hasMatch(text)) {
      minValue ??= 500.0;
      text = text.replaceAll(_expensiveRe, '');
    }
    if (_cheapRe.hasMatch(text)) {
      maxValue ??= 100.0;
      text = text.replaceAll(_cheapRe, '');
    }

    // Date keywords
    if (_recentRe.hasMatch(text)) {
      addedAfter = DateTime.now().subtract(const Duration(days: 30));
      text = text.replaceAll(_recentRe, '');
    }
    if (_thisYearRe.hasMatch(text)) {
      final now = DateTime.now();
      addedAfter = DateTime(now.year);
      text = text.replaceAll(_thisYearRe, '');
    }

    // Presence flags
    if (_withPhotoRe.hasMatch(text)) {
      hasPhoto = true;
      text = text.replaceAll(_withPhotoRe, '');
    }
    if (_withReceiptRe.hasMatch(text)) {
      hasReceipt = true;
      text = text.replaceAll(_withReceiptRe, '');
    }
    if (_withBarcodeRe.hasMatch(text)) {
      hasBarcode = true;
      text = text.replaceAll(_withBarcodeRe, '');
    }

    // Room name matching (fuzzy, case-insensitive)
    final textLower = text.toLowerCase();
    for (final room in rooms) {
      final nameLower = room.name.toLowerCase();
      // Strip common prepositions before trying match
      final strippedText = textLower
          .replaceAll(RegExp(r'\b(in\s+the|in\s+my|in)\s+'), ' ')
          .trim();
      if (strippedText.contains(nameLower) || nameLower.contains(strippedText.split(' ').last)) {
        roomId = room.id;
        text = text.replaceAll(
          RegExp(r'\b(in\s+the\s+|in\s+my\s+|in\s+)?' + RegExp.escape(room.name),
              caseSensitive: false),
          '',
        );
        break;
      }
    }

    // Category name matching
    final textLower2 = text.toLowerCase();
    for (final cat in categories) {
      if (textLower2.contains(cat.name.toLowerCase())) {
        categoryId = cat.id;
        text = text.replaceAll(
          RegExp(RegExp.escape(cat.name), caseSensitive: false),
          '',
        );
        break;
      }
    }

    // Container name matching
    final textLower3 = text.toLowerCase();
    for (final cont in containers) {
      if (textLower3.contains(cont.name.toLowerCase())) {
        containerId = cont.id;
        text = text.replaceAll(
          RegExp(RegExp.escape(cont.name), caseSensitive: false),
          '',
        );
        break;
      }
    }

    // Clean up residual
    final residual = text
        .replaceAll(RegExp(r'\b(the|my|a|an|some|all|items?|stuff|things?|in)\b',
            caseSensitive: false), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    final hasStructured = roomId != null ||
        categoryId != null ||
        containerId != null ||
        minValue != null ||
        maxValue != null ||
        addedAfter != null ||
        hasPhoto != null ||
        hasReceipt != null ||
        hasBarcode != null ||
        sortBy != ItemSortField.name;

    final needsLlmFallback = !hasStructured && residual.length > 3;

    final query = ItemQuery(
      searchText: residual.isEmpty ? null : residual,
      roomId: roomId,
      categoryId: categoryId,
      containerId: containerId,
      minValue: minValue,
      maxValue: maxValue,
      addedAfter: addedAfter,
      hasPhoto: hasPhoto,
      hasReceipt: hasReceipt,
      hasBarcode: hasBarcode,
      sortBy: sortBy,
      ascending: ascending,
    );

    return ParseResult(
      query: query,
      hasStructuredFilters: hasStructured,
      residualText: residual,
      isWhereIs: isWhereIs,
      needsLlmFallback: needsLlmFallback,
    );
  }
}
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/unit/features/search/services/nl_query_parser_test.dart
```

Expected: PASS (all tests). Fix any failures by adjusting the regex patterns — the test expectations are the truth.

**Step 5: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 6: Commit**

```bash
git add lib/features/search/domain/services/nl_query_parser.dart \
        test/unit/features/search/services/nl_query_parser_test.dart
git commit -m "feat: NlQueryParser — pure-Dart rules-based query extraction (15 tests)"
```

---

### Task 6: SavedSearchService

**Files:**
- Create: `lib/features/search/data/services/saved_search_service.dart`
- Modify: `lib/core/providers/repository_providers.dart`
- Test: `test/unit/features/search/services/saved_search_service_test.dart` (new)

**Step 1: Write the failing test**

Create `test/unit/features/search/services/saved_search_service_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/search/data/services/saved_search_service.dart';

class _FakeStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({required String key, IOSOptions? iOptions,
      AndroidOptions? aOptions, LinuxOptions? lOptions,
      WebOptions? webOptions, MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async =>
      _data[key];

  @override
  Future<void> write({required String key, required String? value,
      IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions,
      WebOptions? webOptions, MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }
}

void main() {
  late SavedSearchService service;

  setUp(() {
    service = SavedSearchService(storage: _FakeStorage());
  });

  test('load returns empty list when nothing saved', () async {
    final result = await service.load();
    expect(result, isEmpty);
  });

  test('save and load round-trip', () async {
    await service.save(const SavedSearch(label: 'cameras', query: 'cameras'));
    final result = await service.load();
    expect(result.map((s) => s.label), contains('cameras'));
  });

  test('delete removes by label', () async {
    await service.save(const SavedSearch(label: 'cameras', query: 'cameras'));
    await service.delete('cameras');
    final result = await service.load();
    expect(result, isEmpty);
  });

  test('caps at 20 (LRU — oldest dropped)', () async {
    for (int i = 0; i < 22; i++) {
      await service.save(SavedSearch(label: 'search $i', query: 'search $i'));
    }
    final result = await service.load();
    expect(result.length, equals(20));
    // Oldest (0, 1) should be evicted; newest (21) should be present
    expect(result.map((s) => s.label), contains('search 21'));
    expect(result.map((s) => s.label), isNot(contains('search 0')));
  });

  test('saving duplicate label moves it to front', () async {
    await service.save(const SavedSearch(label: 'query', query: 'query'));
    await service.save(const SavedSearch(label: 'other', query: 'other'));
    await service.save(const SavedSearch(label: 'query', query: 'query'));
    final result = await service.load();
    expect(result.first.label, equals('query'));
    expect(result.length, equals(2));
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/unit/features/search/services/saved_search_service_test.dart
```

Expected: FAIL — file does not exist.

**Step 3: Create SavedSearchService**

Create `lib/features/search/data/services/saved_search_service.dart`:

```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedSearch {
  final String label;
  final String query;
  const SavedSearch({required this.label, required this.query});

  Map<String, dynamic> toJson() => {'label': label, 'query': query};
  factory SavedSearch.fromJson(Map<String, dynamic> j) =>
      SavedSearch(label: j['label'] as String, query: j['query'] as String);
}

class SavedSearchService {
  static const _key = 'saved_searches_v1';
  static const _maxSaved = 20;

  final FlutterSecureStorage _storage;
  SavedSearchService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<List<SavedSearch>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(SavedSearch.fromJson)
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> save(SavedSearch search) async {
    final list = await load();
    list.removeWhere((s) => s.label == search.label);
    list.insert(0, search);
    if (list.length > _maxSaved) list.removeRange(_maxSaved, list.length);
    await _storage.write(key: _key, value: jsonEncode(list.map((s) => s.toJson()).toList()));
  }

  Future<void> delete(String label) async {
    final list = await load();
    list.removeWhere((s) => s.label == label);
    await _storage.write(key: _key, value: jsonEncode(list.map((s) => s.toJson()).toList()));
  }

  Future<void> clear() async {
    await _storage.write(key: _key, value: null);
  }
}
```

**Step 4: Add provider to repository_providers.dart**

In `lib/core/providers/repository_providers.dart`, add:

```dart
import '../features/search/data/services/saved_search_service.dart';
// ...
final savedSearchServiceProvider = Provider<SavedSearchService>((ref) {
  return SavedSearchService();
});
```

**Step 5: Run tests to verify they pass**

```bash
flutter test test/unit/features/search/services/saved_search_service_test.dart
```

Expected: PASS (5 tests).

**Step 6: Run full suite**

```bash
flutter test
```

Expected: all tests pass.

**Step 7: Commit**

```bash
git add lib/features/search/data/services/saved_search_service.dart \
        lib/core/providers/repository_providers.dart \
        test/unit/features/search/services/saved_search_service_test.dart
git commit -m "feat: SavedSearchService — FlutterSecureStorage, 20-item LRU cap"
```

---

### Task 7: SearchController — nlQueryParserProvider + savedSearchesProvider

**Files:**
- Create: `lib/features/search/presentation/controllers/search_controller.dart`

**Step 1: Create the file**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/domain/entities/category.dart';
import '../../../inventory/presentation/controllers/category_controller.dart';
import '../../../locations/domain/entities/room.dart';
import '../../../locations/domain/entities/storage_container.dart';
import '../../../locations/presentation/controllers/location_controller.dart';
import '../../data/services/saved_search_service.dart';
import '../../domain/services/nl_query_parser.dart';

/// A bound NlQueryParser that already has rooms/categories/containers injected.
/// Rebuild automatically when any list changes.
final nlQueryParserProvider = Provider<NlQueryParser>((ref) {
  final rooms = ref.watch(roomsProvider).valueOrNull ?? <Room>[];
  final categories =
      ref.watch(categoriesProvider).valueOrNull ?? <Category>[];
  final containers =
      ref.watch(allContainersProvider).valueOrNull ?? <StorageContainer>[];
  return NlQueryParser(
    rooms: rooms,
    categories: categories,
    containers: containers,
  );
});

/// Reactive list of saved searches (reloads on mutation via ref.invalidate).
final savedSearchesProvider =
    FutureProvider<List<SavedSearch>>((ref) async {
  final service = ref.watch(savedSearchServiceProvider);
  return service.load();
});
```

**Step 2: Run full suite**

```bash
flutter test
```

Expected: all tests pass (no new tests needed for pure provider wiring).

**Step 3: Commit**

```bash
git add lib/features/search/presentation/controllers/search_controller.dart
git commit -m "feat: nlQueryParserProvider + savedSearchesProvider"
```

---

### Task 8: SearchScreen — NL routing + "where is my" card

**Files:**
- Modify: `lib/features/search/presentation/screens/search_screen.dart`
- Test: `test/widget/features/search/screens/search_screen_nl_test.dart` (new)

**Step 1: Write the failing tests**

Create `test/widget/features/search/screens/search_screen_nl_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/locations/domain/entities/room.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';
import 'package:still_life/features/inventory/presentation/controllers/category_controller.dart';
import 'package:still_life/features/search/data/services/saved_search_service.dart';
import 'package:still_life/features/search/presentation/controllers/search_controller.dart';
import 'package:still_life/features/search/presentation/screens/search_screen.dart';
import 'package:still_life/features/inventory/domain/entities/category.dart';

class _FakeItemRepo extends Fake implements ItemRepository {
  final List<Item> items;
  _FakeItemRepo(this.items);

  @override
  Stream<List<Item>> watchItems(ItemQuery query) => Stream.value(items);

  @override
  Stream<List<Item>> searchItems(String query) =>
      Stream.value(items.where((i) => i.name.toLowerCase().contains(query.toLowerCase())).toList());
}

class _FakeSavedSearchService extends Fake implements SavedSearchService {
  @override
  Future<List<SavedSearch>> load() async => [];

  @override
  Future<void> save(SavedSearch search) async {}
}

Item _item(String id, String name, String roomId) => Item(
      id: id, name: name, description: '', categoryId: 'c1', roomId: roomId,
      createdAt: DateTime(2025), modifiedAt: DateTime(2025),
    );

Room _room(String id, String name) => Room(
      id: id, propertyId: 'p', name: name, sortOrder: 0,
      createdAt: DateTime(2025), modifiedAt: DateTime(2025),
    );

Widget _wrap(Widget child, {ItemRepository? repo}) {
  final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => child)]);
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(repo ?? _FakeItemRepo([])),
      roomsProvider.overrideWith((ref) => Stream.value([])),
      categoriesProvider.overrideWith((ref) => Stream.value([])),
      allContainersProvider.overrideWith((ref) => Stream.value([])),
      savedSearchServiceProvider.overrideWithValue(_FakeSavedSearchService()),
      savedSearchesProvider.overrideWith((ref) async => []),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows saved searches chip row when query empty', (tester) async {
    const savedSearchesProvider_override = [SavedSearch(label: 'cameras', query: 'cameras')];
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const SearchScreen())]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        itemRepositoryProvider.overrideWithValue(_FakeItemRepo([])),
        roomsProvider.overrideWith((ref) => Stream.value([])),
        categoriesProvider.overrideWith((ref) => Stream.value([])),
        allContainersProvider.overrideWith((ref) => Stream.value([])),
        savedSearchServiceProvider.overrideWithValue(_FakeSavedSearchService()),
        savedSearchesProvider.overrideWith((ref) async => savedSearchesProvider_override),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('cameras'), findsOneWidget);
  });

  testWidgets('shows where-is card when query starts with "where is"', (tester) async {
    final room = _room('r1', 'Living Room');
    final item = _item('i1', 'Sony Camera', 'r1');
    final repo = _FakeItemRepo([item]);
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const SearchScreen())]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        itemRepositoryProvider.overrideWithValue(repo),
        roomsProvider.overrideWith((ref) => Stream.value([room])),
        categoriesProvider.overrideWith((ref) => Stream.value([])),
        allContainersProvider.overrideWith((ref) => Stream.value([])),
        savedSearchServiceProvider.overrideWithValue(_FakeSavedSearchService()),
        savedSearchesProvider.overrideWith((ref) async => []),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'where is my sony camera');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Where-is card shows room info
    expect(find.text('Living Room'), findsWidgets);
  });

  testWidgets('bookmark button appears when results present', (tester) async {
    final item = _item('i1', 'Camera', 'r1');
    final repo = _FakeItemRepo([item]);
    await tester.pumpWidget(_wrap(const SearchScreen(), repo: repo));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'camera');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/widget/features/search/screens/search_screen_nl_test.dart
```

Expected: FAIL — `SearchScreen` doesn't have saved chips, where-is card, or bookmark button yet.

**Step 3: Update SearchScreen**

Replace `lib/features/search/presentation/screens/search_screen.dart` with the enhanced version:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/domain/repositories/item_repository.dart';
import '../../../inventory/presentation/widgets/item_list_tile.dart';
import '../../../locations/presentation/controllers/location_controller.dart';
import '../../data/services/saved_search_service.dart';
import '../controllers/search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveSearch() async {
    final q = _query.trim();
    if (q.isEmpty) return;
    final service = ref.read(savedSearchServiceProvider);
    await service.save(SavedSearch(label: q, query: q));
    ref.invalidate(savedSearchesProvider);
  }

  void _applyChip(String query) {
    _ctrl.text = query;
    setState(() => _query = query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parser = ref.watch(nlQueryParserProvider);
    final savedAsync = ref.watch(savedSearchesProvider);
    final rooms = ref.watch(roomsProvider).valueOrNull ?? [];

    final parsed = _query.isNotEmpty ? parser.parse(_query) : null;

    // Decide which stream to use
    Stream<List<dynamic>>? resultStream;
    if (parsed != null) {
      if (parsed.hasStructuredFilters || parsed.residualText.isNotEmpty) {
        final effectiveQuery = parsed.hasStructuredFilters
            ? parsed.query
            : ItemQuery(searchText: parsed.residualText);
        if (parsed.hasStructuredFilters) {
          resultStream = ref
              .read(itemRepositoryProvider)
              .watchItems(effectiveQuery);
        } else {
          resultStream = ref
              .read(itemRepositoryProvider)
              .searchItems(parsed.residualText);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search all items…',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? _EmptyState(savedAsync: savedAsync, onChipTap: _applyChip)
          : StreamBuilder<List<dynamic>>(
              stream: resultStream,
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting &&
                    items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return Center(
                    child: Text('No results for "$_query"',
                        style: theme.textTheme.bodyLarge),
                  );
                }
                return Column(
                  children: [
                    // "Where is my" card
                    if (parsed?.isWhereIs == true)
                      _WhereIsCard(items: items, rooms: rooms),
                    // Bookmark button row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _saveSearch,
                            icon: const Icon(Icons.bookmark_outline, size: 18),
                            label: const Text('Save search'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return ItemListTile(
                            item: item,
                            onTap: () => context.pushNamed(
                              'itemDetail',
                              pathParameters: {'itemId': item.id},
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AsyncValue<List<SavedSearch>> savedAsync;
  final ValueChanged<String> onChipTap;

  const _EmptyState({required this.savedAsync, required this.onChipTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = savedAsync.valueOrNull ?? [];

    return Column(
      children: [
        if (saved.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Saved searches',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: saved.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => FilterChip(
                label: Text(saved[i].label),
                onSelected: (_) => onChipTap(saved[i].query),
              ),
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search,
                    size: 64,
                    color: theme.colorScheme.onSurface.withAlpha(60)),
                const SizedBox(height: 12),
                Text(
                  'Type to search all items',
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withAlpha(120)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WhereIsCard extends StatelessWidget {
  final List<dynamic> items;
  final List<dynamic> rooms;

  const _WhereIsCard({required this.items, required this.rooms});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Found', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...items.take(3).map((item) {
              final room = rooms.where((r) => r.id == item.roomId).firstOrNull;
              final roomName = room?.name ?? 'Unknown location';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.name}  ›  $roomName',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/widget/features/search/screens/search_screen_nl_test.dart
```

Expected: PASS. Fix any widget finding issues (use `pump(Duration(milliseconds: 50))` rather than `pumpAndSettle`).

**Step 5: Run full suite**

```bash
flutter test
```

**Step 6: Commit**

```bash
git add lib/features/search/presentation/screens/search_screen.dart \
        test/widget/features/search/screens/search_screen_nl_test.dart
git commit -m "feat: SearchScreen — NL routing, where-is card, saved search chip row + bookmark"
```

---

### Task 9: FilterDialog — presence chips + date pickers

**Files:**
- Modify: `lib/features/inventory/presentation/widgets/filter_dialog.dart`
- Test: `test/widget/features/inventory/widgets/filter_dialog_presence_test.dart` (new)

**Step 1: Write the failing tests**

Create `test/widget/features/inventory/widgets/filter_dialog_presence_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/presentation/controllers/category_controller.dart';
import 'package:still_life/features/inventory/presentation/controllers/tag_controller.dart';
import 'package:still_life/features/inventory/presentation/widgets/filter_dialog.dart';
import 'package:still_life/features/locations/presentation/controllers/location_controller.dart';

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        roomsProvider.overrideWith((ref) => Stream.value([])),
        categoriesProvider.overrideWith((ref) => Stream.value([])),
        tagsProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('presence chips render', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(
      FilterDialog(currentFilter: const FilterResult()),
    ));
    await tester.pump();

    expect(find.text('Has Photo'), findsOneWidget);
    expect(find.text('Has Receipt'), findsOneWidget);
    expect(find.text('Has Barcode'), findsOneWidget);
  });

  testWidgets('tapping Has Photo chip sets hasPhoto in result', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    FilterResult? result;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        roomsProvider.overrideWith((ref) => Stream.value([])),
        categoriesProvider.overrideWith((ref) => Stream.value([])),
        tagsProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<FilterResult>(
                  context: ctx,
                  builder: (_) =>
                      const FilterDialog(currentFilter: FilterResult()),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Has Photo'));
    await tester.pump();
    await tester.tap(find.text('Apply Filters'));
    await tester.pump();

    expect(result?.hasPhoto, isTrue);
  });

  testWidgets('date added range section renders', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(
      const FilterDialog(currentFilter: FilterResult()),
    ));
    await tester.pump();
    expect(find.text('Date Added'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/widget/features/inventory/widgets/filter_dialog_presence_test.dart
```

Expected: FAIL — "Has Photo" chip and "Date Added" section don't exist yet.

**Step 3: Add state vars to _FilterDialogState**

In `lib/features/inventory/presentation/widgets/filter_dialog.dart`, add to `_FilterDialogState`:

```dart
  bool? _hasPhoto;
  bool? _hasReceipt;
  bool? _hasBarcode;
  DateTime? _addedAfter;
  DateTime? _addedBefore;
```

In `initState`, add:

```dart
    _hasPhoto = widget.currentFilter.hasPhoto;
    _hasReceipt = widget.currentFilter.hasReceipt;
    _hasBarcode = widget.currentFilter.hasBarcode;
    _addedAfter = widget.currentFilter.addedAfter;
    _addedBefore = widget.currentFilter.addedBefore;
```

**Step 4: Add presence chips section to ListView children**

After the tag filter section (before the closing `]` of `children`), add:

```dart
                  const SizedBox(height: 16),
                  Text('Presence', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('Has Photo'),
                        selected: _hasPhoto == true,
                        onSelected: (v) =>
                            setState(() => _hasPhoto = v ? true : null),
                      ),
                      FilterChip(
                        label: const Text('Has Receipt'),
                        selected: _hasReceipt == true,
                        onSelected: (v) =>
                            setState(() => _hasReceipt = v ? true : null),
                      ),
                      FilterChip(
                        label: const Text('Has Barcode'),
                        selected: _hasBarcode == true,
                        onSelected: (v) =>
                            setState(() => _hasBarcode = v ? true : null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Date Added', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, size: 20),
                    title: Text(
                      _addedAfter == null
                          ? 'After: any'
                          : 'After: ${_addedAfter!.year}-${_addedAfter!.month.toString().padLeft(2, '0')}-${_addedAfter!.day.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _addedAfter ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _addedAfter = picked);
                      }
                    },
                    trailing: _addedAfter != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => _addedAfter = null),
                          )
                        : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, size: 20),
                    title: Text(
                      _addedBefore == null
                          ? 'Before: any'
                          : 'Before: ${_addedBefore!.year}-${_addedBefore!.month.toString().padLeft(2, '0')}-${_addedBefore!.day.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _addedBefore ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _addedBefore = picked);
                      }
                    },
                    trailing: _addedBefore != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => _addedBefore = null),
                          )
                        : null,
                  ),
```

**Step 5: Update _clearAll()**

```dart
      _hasPhoto = null;
      _hasReceipt = null;
      _hasBarcode = null;
      _addedAfter = null;
      _addedBefore = null;
```

**Step 6: Update _apply()**

```dart
    Navigator.pop(
      context,
      FilterResult(
        roomId: _roomId,
        categoryId: _categoryId,
        tagIds: _tagIds,
        condition: _condition,
        minValue: double.tryParse(_minValueController.text),
        maxValue: double.tryParse(_maxValueController.text),
        priceField: _priceField,
        hasPhoto: _hasPhoto,
        hasReceipt: _hasReceipt,
        hasBarcode: _hasBarcode,
        addedAfter: _addedAfter,
        addedBefore: _addedBefore,
      ),
    );
```

**Step 7: Run tests to verify they pass**

```bash
flutter test test/widget/features/inventory/widgets/filter_dialog_presence_test.dart
```

Expected: PASS (3 tests).

**Step 8: Run full suite**

```bash
flutter test
```

**Step 9: Commit**

```bash
git add lib/features/inventory/presentation/widgets/filter_dialog.dart \
        test/widget/features/inventory/widgets/filter_dialog_presence_test.dart
git commit -m "feat: FilterDialog gains presence chips (photo/receipt/barcode) + date added range"
```

---

### Task 10: InventoryScreen — silent NL routing in search bar

**Files:**
- Modify: `lib/features/inventory/presentation/screens/inventory_screen.dart`

**Step 1: Import SearchController**

At the top of `inventory_screen.dart`, add:

```dart
import '../../domain/services/nl_query_parser.dart' show ParseResult;
import '../../../search/presentation/controllers/search_controller.dart';
```

**Step 2: Wire NL parser into the watchItems call**

The `InventoryScreen` builds an `ItemQuery` from `_currentFilter` + search text. Find the `watchItems` call (it uses `_currentFilter.applyTo(ItemQuery(searchText: ...))` or similar). Replace the search text plumbing to route through the NL parser.

Find where `watchItems` is called (typically inside a `StreamBuilder` or `ref.watch`). The pattern to replace looks like:

```dart
// BEFORE:
final query = _currentFilter.applyTo(
  ItemQuery(searchText: _searchController.text.trim().isEmpty ? null : _searchController.text.trim()),
);
```

Replace with:

```dart
// AFTER:
final rawSearch = _searchController.text.trim();
ItemQuery baseQuery;
if (rawSearch.isNotEmpty) {
  final parsed = ref.read(nlQueryParserProvider).parse(rawSearch);
  // Merge: NL fills fields not set by the manual filter
  baseQuery = ItemQuery(
    searchText: parsed.residualText.isEmpty ? null : parsed.residualText,
    roomId: _currentFilter.roomId ?? parsed.query.roomId,
    categoryId: _currentFilter.categoryId ?? parsed.query.categoryId,
    containerId: parsed.query.containerId,
    minValue: _currentFilter.minValue ?? parsed.query.minValue,
    maxValue: _currentFilter.maxValue ?? parsed.query.maxValue,
    priceField: _currentFilter.priceField,
    hasPhoto: _currentFilter.hasPhoto ?? parsed.query.hasPhoto,
    hasReceipt: _currentFilter.hasReceipt ?? parsed.query.hasReceipt,
    hasBarcode: _currentFilter.hasBarcode ?? parsed.query.hasBarcode,
    sortBy: parsed.query.sortBy,
    ascending: parsed.query.ascending,
  );
} else {
  baseQuery = _currentFilter.applyTo(const ItemQuery());
}
```

**Note:** Read the full `inventory_screen.dart` first to find the exact location and adapt accordingly. The key principle is: NL fills gaps, manual filter takes precedence for fields the user explicitly set.

**Step 2: Run full suite**

```bash
flutter test
```

Expected: all tests pass. (No new tests needed — the NL parser is already fully unit-tested; the inventory screen integration is covered by existing tests.)

**Step 3: Run analyze**

```bash
flutter analyze
```

Expected: 0 issues.

**Step 4: Commit**

```bash
git add lib/features/inventory/presentation/screens/inventory_screen.dart
git commit -m "feat: InventoryScreen search bar routes through NL parser silently"
```

---

### Task 11: Final verification + tag

**Step 1: Run full test suite**

```bash
flutter test
```

Expected: 400+ tests passing (was 377, added ~25 new tests across Tasks 1–9).

**Step 2: Run analyzer**

```bash
flutter analyze
```

Expected: 0 issues.

**Step 3: Build debug APK**

```bash
flutter build apk --debug
```

Expected: BUILD SUCCESSFUL.

**Step 4: Manual smoke-test checklist**

- Open SearchScreen → type "expensive stuff in the garage" → filtered results appear
- Type "where is my camera" → where-is card shows room name above results
- Tap bookmark → saved search chip appears on empty state → tapping chip fills bar
- Open FilterDialog → "Has Photo" chip toggles → Apply → inventory filtered
- Date added range pickers in filter dialog open calendar
- InventoryScreen search bar → type "garage electronics" → filters to that room + category
- Back in SearchScreen → clear → type → type → normal FTS still works

**Step 5: Commit tag**

```bash
git tag -a v0.16.0 -m "Phase 16: NL Search + Smart Filters (400+ tests)"
```

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/csv_export_service.dart';

import '../../../test_setup.dart';

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late CsvExportService svc;

  setUp(() async {
    db = AppDatabase.memory();
    svc = CsvExportService(db);

    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat1',
            name: 'Electronics',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
    await db
        .into(db.properties)
        .insert(
          PropertiesCompanion.insert(
            id: 'prop1',
            name: 'Home',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
    await db
        .into(db.rooms)
        .insert(
          RoomsCompanion.insert(
            id: 'room1',
            propertyId: 'prop1',
            name: 'Living Room',
            createdAt: DateTime(2025),
            modifiedAt: DateTime(2025),
          ),
        );
  });

  tearDown(() => db.close());

  group('CsvExportService', () {
    test('exports header row with expected columns', () async {
      final csv = await svc.exportItemsToCsv();
      final header = csv.split('\n').first;
      expect(header, contains('"Name"'));
      expect(header, contains('"Category"'));
      expect(header, contains('"Room"'));
      expect(header, contains('"Current Value"'));
      expect(header, contains('"Label ID"'));
      expect(header, contains('"Tags"'));
    });

    test('returns only header when no items', () async {
      final csv = await svc.exportItemsToCsv();
      final lines = csv.trim().split('\n');
      expect(lines.length, 1); // header only
    });

    test('exports item row with denormalized names', () async {
      final now = DateTime(2025, 6, 1);
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'item1',
              name: 'Samsung TV',
              categoryId: 'cat1',
              roomId: 'room1',
              isInsured: const Value(true),
              purchasePrice: const Value(1200.0),
              currentValue: const Value(900.0),
              createdAt: now,
              modifiedAt: now,
            ),
          );

      final csv = await svc.exportItemsToCsv();
      expect(csv, contains('"Samsung TV"'));
      expect(csv, contains('"Electronics"'));
      expect(csv, contains('"Living Room"'));
      expect(csv, contains('"1200.00"'));
      expect(csv, contains('"900.00"'));
      expect(csv, contains('"Yes"')); // insured
    });

    test('excludes soft-deleted items', () async {
      final now = DateTime(2025, 6, 1);
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'item1',
              name: 'Deleted TV',
              categoryId: 'cat1',
              roomId: 'room1',
              isDeleted: const Value(true),
              createdAt: now,
              modifiedAt: now,
            ),
          );

      final csv = await svc.exportItemsToCsv();
      expect(csv, isNot(contains('Deleted TV')));
    });

    test('includes tags as semicolon-separated list', () async {
      final now = DateTime(2025, 6, 1);
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'item1',
              name: 'Laptop',
              categoryId: 'cat1',
              roomId: 'room1',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              id: 'tag1',
              name: 'Work',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              id: 'tag2',
              name: 'Tech',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.itemTags)
          .insert(
            ItemTagsCompanion.insert(
              itemId: 'item1',
              tagId: 'tag1',
              createdAt: now,
            ),
          );
      await db
          .into(db.itemTags)
          .insert(
            ItemTagsCompanion.insert(
              itemId: 'item1',
              tagId: 'tag2',
              createdAt: now,
            ),
          );

      final csv = await svc.exportItemsToCsv();
      // Tags appear in the Tags column — order is DB-defined, check both.
      expect(csv, anyOf(contains('Work; Tech'), contains('Tech; Work')));
    });

    test('excludes soft-deleted tags and itemTags from Tags column', () async {
      final now = DateTime(2025, 6, 1);
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'item1',
              name: 'Laptop',
              categoryId: 'cat1',
              roomId: 'room1',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      // Live tag.
      await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              id: 'tag-live',
              name: 'Work',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      // Tag soft-deleted in DB (must not appear).
      await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              id: 'tag-dead',
              name: 'OldTag',
              isDeleted: const Value(true),
              createdAt: now,
              modifiedAt: now,
            ),
          );
      // Junction soft-deleted (must not surface live tag either).
      await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              id: 'tag-orphan',
              name: 'Orphan',
              createdAt: now,
              modifiedAt: now,
            ),
          );
      await db
          .into(db.itemTags)
          .insert(
            ItemTagsCompanion.insert(
              itemId: 'item1',
              tagId: 'tag-live',
              createdAt: now,
            ),
          );
      await db
          .into(db.itemTags)
          .insert(
            ItemTagsCompanion.insert(
              itemId: 'item1',
              tagId: 'tag-dead',
              createdAt: now,
            ),
          );
      await db
          .into(db.itemTags)
          .insert(
            ItemTagsCompanion.insert(
              itemId: 'item1',
              tagId: 'tag-orphan',
              createdAt: now,
              isDeleted: const Value(true),
            ),
          );

      final csv = await svc.exportItemsToCsv();
      expect(csv, contains('Work'));
      expect(csv, isNot(contains('OldTag')));
      expect(csv, isNot(contains('Orphan')));
    });

    test('quotes fields containing commas', () async {
      final now = DateTime(2025, 6, 1);
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'item1',
              name: 'TV, Large',
              categoryId: 'cat1',
              roomId: 'room1',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      final csv = await svc.exportItemsToCsv();
      // Comma in name must be inside quotes so CSV parsers handle it.
      expect(csv, contains('"TV, Large"'));
    });

    test('escapes embedded double quotes per RFC 4180', () async {
      final now = DateTime(2025, 6, 1);
      await db
          .into(db.items)
          .insert(
            ItemsCompanion.insert(
              id: 'item1',
              name: 'He said "hello"',
              categoryId: 'cat1',
              roomId: 'room1',
              createdAt: now,
              modifiedAt: now,
            ),
          );

      final csv = await svc.exportItemsToCsv();
      expect(csv, contains('"He said ""hello"""'));
    });
  });
}

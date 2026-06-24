import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/inventory/domain/repositories/item_repository.dart';
import 'package:still_life/features/locations/domain/entities/room.dart';
import 'package:still_life/features/locations/domain/entities/storage_container.dart';
import 'package:still_life/features/inventory/domain/entities/category.dart';
import 'package:still_life/features/search/domain/services/nl_query_parser.dart';

// Helpers — adapted to match real entity constructors.
// Category uses iconCodePoint (int?), not iconName/color.
Room _room(String id, String name) => Room(
  id: id,
  propertyId: 'p',
  name: name,
  sortOrder: 0,
  createdAt: DateTime(2025),
  modifiedAt: DateTime(2025),
);

Category _cat(String id, String name) => Category(
  id: id,
  name: name,
  createdAt: DateTime(2025),
  modifiedAt: DateTime(2025),
);

NlQueryParser _parser({
  List<Room>? rooms,
  List<Category>? categories,
  List<StorageContainer>? containers,
}) => NlQueryParser(
  rooms: rooms ?? [],
  categories: categories ?? [],
  containers: containers ?? [],
);

void main() {
  group('price keywords', () {
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
    });

    test('"cheap" sets maxValue=100', () {
      final r = _parser().parse('cheap stuff');
      expect(r.query.maxValue, equals(100.0));
    });
  });

  group('room matching', () {
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
      expect(r.residualText.toLowerCase(), isNot(contains('garage')));
    });

    test('short room name does not match embedded substring', () {
      final rooms = [_room('d1', 'Den')];
      final r = _parser(rooms: rooms).parse('wooden cabinet');
      expect(r.query.roomId, isNull);
    });
  });

  group('category matching', () {
    final cats = [_cat('el', 'Electronics'), _cat('furn', 'Furniture')];

    test('extracts categoryId from category name', () {
      final r = _parser(categories: cats).parse('electronics over \$100');
      expect(r.query.categoryId, equals('el'));
    });
  });

  group('date keywords', () {
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

    test('"recent items this year" uses first match (recent), not both', () {
      final r = _parser().parse('recent items this year');
      expect(r.query.addedAfter, isNotNull);
      // First match wins: should be ~30 days ago, not Jan 1
      final age = DateTime.now().difference(r.query.addedAfter!).inDays;
      expect(age, closeTo(30, 2));
    });
  });

  group('presence flags', () {
    test('"with photo" sets hasPhoto=true', () {
      expect(_parser().parse('items with photo').query.hasPhoto, isTrue);
    });

    test('"has receipt" sets hasReceipt=true', () {
      expect(_parser().parse('stuff has receipt').query.hasReceipt, isTrue);
    });

    test('"with barcode" sets hasBarcode=true', () {
      expect(_parser().parse('with barcode').query.hasBarcode, isTrue);
    });
  });

  group('sort keywords', () {
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

  group('where-is mode', () {
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

  group('edge cases', () {
    test('empty input returns empty result', () {
      final r = _parser().parse('');
      expect(r.hasStructuredFilters, isFalse);
      expect(r.residualText, isEmpty);
      expect(r.needsLlmFallback, isFalse);
    });

    test('short gibberish does not set needsLlmFallback', () {
      expect(_parser().parse('xy').needsLlmFallback, isFalse);
    });

    test('unrecognised text longer than 3 chars sets needsLlmFallback', () {
      expect(
        _parser().parse('whatchamacallit thingy').needsLlmFallback,
        isTrue,
      );
    });
  });
}

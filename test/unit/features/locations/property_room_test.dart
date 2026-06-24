import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/locations/domain/entities/property.dart';
import 'package:still_life/features/locations/domain/entities/room.dart';

void main() {
  group('Property entity', () {
    test('PropertyType.fromString parses known types', () {
      expect(PropertyType.fromString('Home'), PropertyType.home);
      expect(PropertyType.fromString('Apartment'), PropertyType.apartment);
      expect(
        PropertyType.fromString('Vacation Home'),
        PropertyType.vacationHome,
      );
      expect(PropertyType.fromString('Storage Unit'), PropertyType.storageUnit);
    });

    test('PropertyType.fromString defaults to other for unknown', () {
      expect(PropertyType.fromString('Unknown'), PropertyType.other);
    });

    test('equality works correctly', () {
      final now = DateTime(2024, 1, 1);
      final p1 = Property(
        id: '1',
        name: 'Home',
        createdAt: now,
        modifiedAt: now,
      );
      final p2 = Property(
        id: '1',
        name: 'Home',
        createdAt: now,
        modifiedAt: now,
      );
      expect(p1, equals(p2));
    });

    test('copyWith updates fields', () {
      final now = DateTime(2024, 1, 1);
      final property = Property(
        id: '1',
        name: 'Home',
        address: '123 Main St',
        createdAt: now,
        modifiedAt: now,
      );

      final updated = property.copyWith(name: 'My House');
      expect(updated.name, 'My House');
      expect(updated.address, '123 Main St');
    });
  });

  group('Room entity', () {
    test('displayPath includes property, floor, and room name', () {
      final now = DateTime(2024, 1, 1);
      final room = Room(
        id: '1',
        propertyId: 'prop1',
        name: 'Master Bedroom',
        floor: '2nd Floor',
        propertyName: 'Home',
        createdAt: now,
        modifiedAt: now,
      );

      expect(room.displayPath, 'Home > 2nd Floor > Master Bedroom');
    });

    test('displayPath works without floor', () {
      final now = DateTime(2024, 1, 1);
      final room = Room(
        id: '1',
        propertyId: 'prop1',
        name: 'Garage',
        propertyName: 'Home',
        createdAt: now,
        modifiedAt: now,
      );

      expect(room.displayPath, 'Home > Garage');
    });

    test('displayPath works without property name', () {
      final now = DateTime(2024, 1, 1);
      final room = Room(
        id: '1',
        propertyId: 'prop1',
        name: 'Kitchen',
        createdAt: now,
        modifiedAt: now,
      );

      expect(room.displayPath, 'Kitchen');
    });

    test('equality works correctly', () {
      final now = DateTime(2024, 1, 1);
      final r1 = Room(
        id: '1',
        propertyId: 'prop1',
        name: 'Room',
        createdAt: now,
        modifiedAt: now,
      );
      final r2 = Room(
        id: '1',
        propertyId: 'prop1',
        name: 'Room',
        createdAt: now,
        modifiedAt: now,
      );
      expect(r1, equals(r2));
    });
  });
}

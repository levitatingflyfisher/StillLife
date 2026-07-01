import 'package:equatable/equatable.dart';

enum PropertyType {
  home('Home'),
  apartment('Apartment'),
  vacationHome('Vacation Home'),
  storageUnit('Storage Unit'),
  office('Office'),
  other('Other');

  final String label;
  const PropertyType(this.label);

  static PropertyType fromString(String value) {
    return PropertyType.values.firstWhere(
      (e) => e.label == value || e.name == value,
      orElse: () => PropertyType.other,
    );
  }
}

class Property extends Equatable {
  final String id;
  final String name;
  final String? address;
  final PropertyType type;
  final DateTime createdAt;
  final DateTime modifiedAt;

  // Derived
  final int roomCount;
  final int itemCount;
  /// Integer cents (see core/utils/money.dart).
  final int totalValueCents;

  const Property({
    required this.id,
    required this.name,
    this.address,
    this.type = PropertyType.home,
    required this.createdAt,
    required this.modifiedAt,
    this.roomCount = 0,
    this.itemCount = 0,
    this.totalValueCents = 0,
  });

  Property copyWith({
    String? id,
    String? name,
    String? Function()? address,
    PropertyType? type,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? roomCount,
    int? itemCount,
    int? totalValueCents,
  }) {
    return Property(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address != null ? address() : this.address,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      roomCount: roomCount ?? this.roomCount,
      itemCount: itemCount ?? this.itemCount,
      totalValueCents: totalValueCents ?? this.totalValueCents,
    );
  }

  @override
  List<Object?> get props => [id, name, address, type, createdAt, modifiedAt];
}

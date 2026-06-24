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
  final double totalValue;

  const Property({
    required this.id,
    required this.name,
    this.address,
    this.type = PropertyType.home,
    required this.createdAt,
    required this.modifiedAt,
    this.roomCount = 0,
    this.itemCount = 0,
    this.totalValue = 0.0,
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
    double? totalValue,
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
      totalValue: totalValue ?? this.totalValue,
    );
  }

  @override
  List<Object?> get props => [id, name, address, type, createdAt, modifiedAt];
}

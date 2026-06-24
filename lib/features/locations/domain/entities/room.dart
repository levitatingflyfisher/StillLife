import 'package:equatable/equatable.dart';

class Room extends Equatable {
  final String id;
  final String propertyId;
  final String? parentId;
  final String name;
  final String? floor;
  final int sortOrder;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime modifiedAt;

  // Derived
  final int itemCount;
  final double totalValue;
  final String? propertyName;

  const Room({
    required this.id,
    required this.propertyId,
    this.parentId,
    required this.name,
    this.floor,
    this.sortOrder = 0,
    this.photoPath,
    required this.createdAt,
    required this.modifiedAt,
    this.itemCount = 0,
    this.totalValue = 0.0,
    this.propertyName,
  });

  Room copyWith({
    String? id,
    String? propertyId,
    String? Function()? parentId,
    String? name,
    String? Function()? floor,
    int? sortOrder,
    String? Function()? photoPath,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? itemCount,
    double? totalValue,
    String? propertyName,
  }) {
    return Room(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      parentId: parentId != null ? parentId() : this.parentId,
      name: name ?? this.name,
      floor: floor != null ? floor() : this.floor,
      sortOrder: sortOrder ?? this.sortOrder,
      photoPath: photoPath != null ? photoPath() : this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      itemCount: itemCount ?? this.itemCount,
      totalValue: totalValue ?? this.totalValue,
      propertyName: propertyName ?? this.propertyName,
    );
  }

  String get displayPath {
    final parts = <String>[];
    if (propertyName != null) parts.add(propertyName!);
    if (floor != null) parts.add(floor!);
    parts.add(name);
    return parts.join(' > ');
  }

  @override
  List<Object?> get props => [
    id,
    propertyId,
    parentId,
    name,
    floor,
    sortOrder,
    photoPath,
    createdAt,
    modifiedAt,
  ];
}

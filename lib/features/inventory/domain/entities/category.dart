import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final int? iconCodePoint;
  final DateTime createdAt;
  final DateTime modifiedAt;

  // Derived
  final int itemCount;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.iconCodePoint,
    required this.createdAt,
    required this.modifiedAt,
    this.itemCount = 0,
  });

  Category copyWith({
    String? id,
    String? name,
    String? Function()? parentId,
    int? Function()? iconCodePoint,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? itemCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId != null ? parentId() : this.parentId,
      iconCodePoint: iconCodePoint != null
          ? iconCodePoint()
          : this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    parentId,
    iconCodePoint,
    createdAt,
    modifiedAt,
  ];
}

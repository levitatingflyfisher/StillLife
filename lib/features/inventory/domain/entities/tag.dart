import 'package:equatable/equatable.dart';

class Tag extends Equatable {
  final String id;
  final String name;
  final int? color;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const Tag({
    required this.id,
    required this.name,
    this.color,
    required this.createdAt,
    required this.modifiedAt,
  });

  Tag copyWith({
    String? id,
    String? name,
    int? Function()? color,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color != null ? color() : this.color,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, color, createdAt, modifiedAt];
}

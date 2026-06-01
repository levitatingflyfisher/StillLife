import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String name;
  final String colorHex;
  final String avatarEmoji;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const Profile({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.avatarEmoji,
    required this.isDefault,
    required this.createdAt,
    required this.modifiedAt,
  });

  Profile copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? avatarEmoji,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    colorHex,
    avatarEmoji,
    isDefault,
    createdAt,
    modifiedAt,
  ];
}

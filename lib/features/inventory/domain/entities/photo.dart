import 'package:equatable/equatable.dart';

enum PhotoSource { camera, gallery, videoFrame }

class Photo extends Equatable {
  final String id;
  final String itemId;
  final String filePath;
  final bool isPrimary;
  final PhotoSource source;
  final DateTime capturedAt;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const Photo({
    required this.id,
    required this.itemId,
    required this.filePath,
    this.isPrimary = false,
    required this.source,
    required this.capturedAt,
    required this.createdAt,
    required this.modifiedAt,
  });

  Photo copyWith({
    String? id,
    String? itemId,
    String? filePath,
    bool? isPrimary,
    PhotoSource? source,
    DateTime? capturedAt,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Photo(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      filePath: filePath ?? this.filePath,
      isPrimary: isPrimary ?? this.isPrimary,
      source: source ?? this.source,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemId,
    filePath,
    isPrimary,
    source,
    capturedAt,
    createdAt,
    modifiedAt,
  ];
}

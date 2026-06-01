import 'package:equatable/equatable.dart';

class StorageContainer extends Equatable {
  final String id;
  final String roomId;
  final String name;
  final String? type; // shelf, box, drawer, cabinet, closet, etc.
  final DateTime createdAt;
  final DateTime modifiedAt;

  const StorageContainer({
    required this.id,
    required this.roomId,
    required this.name,
    this.type,
    required this.createdAt,
    required this.modifiedAt,
  });

  @override
  List<Object?> get props => [id, roomId, name, type, createdAt, modifiedAt];
}

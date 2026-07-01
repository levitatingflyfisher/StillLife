import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum PhotoSource { camera, gallery, videoFrame }

class Photo extends Equatable {
  final String id;
  final String itemId;

  /// Legacy pre-v12 on-disk location; '' for byte-backed photos.
  final String filePath;

  /// Full-size photo bytes. Null only for legacy rows whose backing file was
  /// already gone at migration time — display a placeholder then.
  final Uint8List? bytes;

  /// Small JPEG thumbnail derived from [bytes]; best-effort, may be null.
  final Uint8List? thumbBytes;

  final bool isPrimary;
  final PhotoSource source;
  final DateTime capturedAt;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const Photo({
    required this.id,
    required this.itemId,
    required this.filePath,
    this.bytes,
    this.thumbBytes,
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
    Uint8List? bytes,
    Uint8List? thumbBytes,
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
      bytes: bytes ?? this.bytes,
      thumbBytes: thumbBytes ?? this.thumbBytes,
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
    bytes,
    thumbBytes,
    isPrimary,
    source,
    capturedAt,
    createdAt,
    modifiedAt,
  ];
}

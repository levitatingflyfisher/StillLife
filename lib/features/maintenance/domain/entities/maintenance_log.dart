import 'package:equatable/equatable.dart';

class MaintenanceLog extends Equatable {
  final String id;
  final String? itemId;
  final String? propertyId;
  final String title;
  final String? description;
  final double? cost;
  final DateTime performedAt;
  final DateTime? nextDueAt;
  final String? servicedBy;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const MaintenanceLog({
    required this.id,
    this.itemId,
    this.propertyId,
    required this.title,
    this.description,
    this.cost,
    required this.performedAt,
    this.nextDueAt,
    this.servicedBy,
    required this.createdAt,
    required this.modifiedAt,
  });

  bool get isDue => nextDueAt != null && nextDueAt!.isBefore(DateTime.now());

  MaintenanceLog copyWith({
    String? id,
    Object? itemId = _sentinel,
    Object? propertyId = _sentinel,
    String? title,
    Object? description = _sentinel,
    Object? cost = _sentinel,
    DateTime? performedAt,
    Object? nextDueAt = _sentinel,
    Object? servicedBy = _sentinel,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return MaintenanceLog(
      id: id ?? this.id,
      itemId: itemId == _sentinel ? this.itemId : itemId as String?,
      propertyId: propertyId == _sentinel
          ? this.propertyId
          : propertyId as String?,
      title: title ?? this.title,
      description: description == _sentinel
          ? this.description
          : description as String?,
      cost: cost == _sentinel ? this.cost : cost as double?,
      performedAt: performedAt ?? this.performedAt,
      nextDueAt: nextDueAt == _sentinel
          ? this.nextDueAt
          : nextDueAt as DateTime?,
      servicedBy: servicedBy == _sentinel
          ? this.servicedBy
          : servicedBy as String?,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [id];
}

// Sentinel value for distinguishing "not provided" from explicit null in copyWith.
const _sentinel = Object();

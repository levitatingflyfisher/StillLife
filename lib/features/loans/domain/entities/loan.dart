import 'package:equatable/equatable.dart';

class Loan extends Equatable {
  final String id;
  final String itemId;
  final String itemName; // denormalised from Items join
  final String borrowerName;
  final DateTime? expectedReturnDate;
  final String? notes;
  final DateTime? returnedAt;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const Loan({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.borrowerName,
    this.expectedReturnDate,
    this.notes,
    this.returnedAt,
    required this.createdAt,
    required this.modifiedAt,
  });

  bool get isActive => returnedAt == null;

  bool get isOverdue =>
      isActive &&
      expectedReturnDate != null &&
      expectedReturnDate!.isBefore(DateTime.now());

  /// Due within 3 days, not yet overdue (threshold matches AllLoansScreen grouping).
  bool get isDueSoon =>
      isActive &&
      expectedReturnDate != null &&
      !isOverdue &&
      expectedReturnDate!.difference(DateTime.now()).inDays <= 3;

  Loan copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? borrowerName,
    DateTime? Function()? expectedReturnDate,
    String? Function()? notes,
    DateTime? Function()? returnedAt,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) => Loan(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    itemName: itemName ?? this.itemName,
    borrowerName: borrowerName ?? this.borrowerName,
    expectedReturnDate: expectedReturnDate != null
        ? expectedReturnDate()
        : this.expectedReturnDate,
    notes: notes != null ? notes() : this.notes,
    returnedAt: returnedAt != null ? returnedAt() : this.returnedAt,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
  );

  @override
  List<Object?> get props => [
    id,
    itemId,
    itemName,
    borrowerName,
    expectedReturnDate,
    notes,
    returnedAt,
    createdAt,
    modifiedAt,
  ];
}

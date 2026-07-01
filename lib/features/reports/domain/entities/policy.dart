import 'package:equatable/equatable.dart';

class Policy extends Equatable {
  final String id;
  final String propertyId;
  final String provider;
  final String? policyNumber;
  /// Money is integer cents throughout the domain (see core/utils/money.dart).
  final int? coverageAmountCents;
  final int? deductibleCents;
  final int? premiumCents;
  final DateTime? expiryDate;
  final DateTime createdAt;

  const Policy({
    required this.id,
    required this.propertyId,
    required this.provider,
    this.policyNumber,
    this.coverageAmountCents,
    this.deductibleCents,
    this.premiumCents,
    this.expiryDate,
    required this.createdAt,
  });

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  Policy copyWith({
    String? id,
    String? propertyId,
    String? provider,
    String? policyNumber,
    int? coverageAmountCents,
    int? deductibleCents,
    int? premiumCents,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return Policy(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      provider: provider ?? this.provider,
      policyNumber: policyNumber ?? this.policyNumber,
      coverageAmountCents: coverageAmountCents ?? this.coverageAmountCents,
      deductibleCents: deductibleCents ?? this.deductibleCents,
      premiumCents: premiumCents ?? this.premiumCents,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id];
}

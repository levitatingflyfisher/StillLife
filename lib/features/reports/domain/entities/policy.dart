import 'package:equatable/equatable.dart';

class Policy extends Equatable {
  final String id;
  final String propertyId;
  final String provider;
  final String? policyNumber;
  final double? coverageAmount;
  final double? deductible;
  final double? premium;
  final DateTime? expiryDate;
  final DateTime createdAt;

  const Policy({
    required this.id,
    required this.propertyId,
    required this.provider,
    this.policyNumber,
    this.coverageAmount,
    this.deductible,
    this.premium,
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
    double? coverageAmount,
    double? deductible,
    double? premium,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return Policy(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      provider: provider ?? this.provider,
      policyNumber: policyNumber ?? this.policyNumber,
      coverageAmount: coverageAmount ?? this.coverageAmount,
      deductible: deductible ?? this.deductible,
      premium: premium ?? this.premium,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id];
}

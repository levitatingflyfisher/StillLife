import 'package:equatable/equatable.dart';

import 'appraisal_source.dart';

/// Three market-value modes we estimate per item.
enum AppraisalMode {
  resale('resale', 'Resale'),
  replaceNew('replace_new', 'Replace New'),
  replaceEquivalent('replace_equivalent', 'Replace Equivalent');

  final String wire;
  final String label;
  const AppraisalMode(this.wire, this.label);

  static AppraisalMode fromWire(String s) =>
      values.firstWhere((m) => m.wire == s, orElse: () => resale);
}

/// A cached market-value estimate for a specific `(item, mode)` pair.
class Appraisal extends Equatable {
  final String id;
  final String itemId;
  final AppraisalMode mode;
  final double value;
  final String currency;
  final double confidence;
  final List<AppraisalSource> sources;
  final String itemModelKey;
  final String countryCode;
  final DateTime queriedAt;
  final DateTime expiresAt;

  const Appraisal({
    required this.id,
    required this.itemId,
    required this.mode,
    required this.value,
    required this.currency,
    required this.confidence,
    required this.sources,
    required this.itemModelKey,
    required this.countryCode,
    required this.queriedAt,
    required this.expiresAt,
  });

  /// Cache is still valid: expiresAt in the future.
  bool get isFresh => expiresAt.isAfter(DateTime.now());

  /// True when the LLM returned a non-zero-confidence estimate.
  bool get hasData => confidence > 0.0 && value > 0.0;

  Appraisal copyWith({
    String? id,
    String? itemId,
    AppraisalMode? mode,
    double? Function()? value,
    String? Function()? currency,
    double? Function()? confidence,
    List<AppraisalSource>? Function()? sources,
    String? itemModelKey,
    String? countryCode,
    DateTime? queriedAt,
    DateTime? Function()? expiresAt,
  }) => Appraisal(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    mode: mode ?? this.mode,
    value: value == null ? this.value : value() ?? this.value,
    currency: currency == null ? this.currency : currency() ?? this.currency,
    confidence: confidence == null
        ? this.confidence
        : confidence() ?? this.confidence,
    sources: sources == null ? this.sources : sources() ?? this.sources,
    itemModelKey: itemModelKey ?? this.itemModelKey,
    countryCode: countryCode ?? this.countryCode,
    queriedAt: queriedAt ?? this.queriedAt,
    expiresAt: expiresAt == null
        ? this.expiresAt
        : expiresAt() ?? this.expiresAt,
  );

  @override
  List<Object?> get props => [
    id,
    itemId,
    mode,
    value,
    currency,
    confidence,
    sources,
    itemModelKey,
    countryCode,
    queriedAt,
    expiresAt,
  ];
}

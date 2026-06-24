import 'dart:convert';

/// The payload exchanged between two Still Life nodes during a sync.
class SyncChangeset {
  final String senderNodeId;
  final String senderHlc;
  final Map<String, dynamic> data;

  const SyncChangeset({
    required this.senderNodeId,
    required this.senderHlc,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'senderNodeId': senderNodeId,
    'senderHlc': senderHlc,
    'data': data,
  };

  factory SyncChangeset.fromJson(Map<String, dynamic> json) => SyncChangeset(
    senderNodeId: json['senderNodeId'] as String? ?? '',
    senderHlc: json['senderHlc'] as String? ?? '',
    data: json['data'] as Map<String, dynamic>? ?? {},
  );

  String toJsonString() => const JsonEncoder().convert(toJson());

  factory SyncChangeset.fromJsonString(String s) =>
      SyncChangeset.fromJson(json.decode(s) as Map<String, dynamic>);
}

import 'dart:convert';

/// The payload exchanged between two Still Life nodes during a sync.
class SyncChangeset {
  /// Version of the PAYLOAD semantics (row shapes, units — today: money as
  /// decimal dollars under the export keys). Distinct from
  /// SyncCodec.protocolVersion, which covers only the crypto wire. Bump this
  /// when payload meaning changes so an older peer refuses the merge instead
  /// of silently misreading it; changesets from before the field existed
  /// parse as version 1.
  static const int currentPayloadSchemaVersion = 1;

  final String senderNodeId;
  final String senderHlc;
  final Map<String, dynamic> data;
  final int payloadSchemaVersion;

  const SyncChangeset({
    required this.senderNodeId,
    required this.senderHlc,
    required this.data,
    this.payloadSchemaVersion = currentPayloadSchemaVersion,
  });

  Map<String, dynamic> toJson() => {
    'senderNodeId': senderNodeId,
    'senderHlc': senderHlc,
    'data': data,
    'payloadSchemaVersion': payloadSchemaVersion,
  };

  factory SyncChangeset.fromJson(Map<String, dynamic> json) => SyncChangeset(
    senderNodeId: json['senderNodeId'] as String? ?? '',
    senderHlc: json['senderHlc'] as String? ?? '',
    data: json['data'] as Map<String, dynamic>? ?? {},
    payloadSchemaVersion: json['payloadSchemaVersion'] as int? ?? 1,
  );

  String toJsonString() => const JsonEncoder().convert(toJson());

  factory SyncChangeset.fromJsonString(String s) =>
      SyncChangeset.fromJson(json.decode(s) as Map<String, dynamic>);
}

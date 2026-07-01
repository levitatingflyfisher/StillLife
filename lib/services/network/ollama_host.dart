/// A discovered Ollama instance on the local network.
class OllamaHost {
  final String hostname;
  final String ipAddress;
  final int port;

  const OllamaHost({
    required this.hostname,
    required this.ipAddress,
    required this.port,
  });

  /// The base URL for this Ollama instance.
  String get baseUrl => 'http://$ipAddress:$port';

  @override
  String toString() => 'OllamaHost($hostname @ $ipAddress:$port)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OllamaHost && ipAddress == other.ipAddress && port == other.port;

  @override
  int get hashCode => Object.hash(ipAddress, port);
}

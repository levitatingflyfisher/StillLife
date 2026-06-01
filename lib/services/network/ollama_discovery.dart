import 'dart:async';

import 'package:dio/dio.dart';
import 'package:nsd/nsd.dart';

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

/// Discovers Ollama instances on the local network via mDNS/DNS-SD
/// and supports manual host validation.
class OllamaDiscovery {
  final Dio _dio;

  /// The mDNS service type to search for.
  /// Ollama does not register a standard service type, so we scan for
  /// HTTP services and filter by checking the Ollama API endpoint.
  static const String _serviceType = '_http._tcp';

  /// Default Ollama port.
  static const int defaultPort = 11434;

  OllamaDiscovery({required Dio dio}) : _dio = dio;

  /// Discovers Ollama instances on the local network.
  ///
  /// Uses mDNS/DNS-SD to find HTTP services, then probes each discovered
  /// host on the Ollama default port to see if it responds with the
  /// Ollama API.
  Stream<OllamaHost> discoverOllamaInstances({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    final seen = <String>{};
    Discovery? discovery;

    try {
      discovery = await startDiscovery(_serviceType);

      // Poll the discovered services until timeout.
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        for (final service in discovery.services) {
          final host = service.host;
          final addresses = service.addresses;

          if (host == null || addresses == null || addresses.isEmpty) continue;

          final ip = addresses.first.address;
          final key = '$ip:$defaultPort';
          if (seen.contains(key)) continue;

          // Probe this host for Ollama on the default port.
          if (await testConnection(ip, defaultPort)) {
            seen.add(key);
            yield OllamaHost(hostname: host, ipAddress: ip, port: defaultPort);
          }

          // Also check on the service's advertised port if different.
          final port = service.port;
          if (port != null && port != defaultPort) {
            final altKey = '$ip:$port';
            if (!seen.contains(altKey) && await testConnection(ip, port)) {
              seen.add(altKey);
              yield OllamaHost(hostname: host, ipAddress: ip, port: port);
            }
          }
        }

        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } catch (_) {
      // Discovery may fail on some platforms — that is OK.
    } finally {
      if (discovery != null) {
        try {
          await stopDiscovery(discovery);
        } catch (_) {
          // Ignore stop errors.
        }
      }
    }
  }

  /// Tests whether an Ollama instance is reachable at the given
  /// [host] and [port] by calling its `/api/tags` endpoint.
  Future<bool> testConnection(String host, int port) async {
    try {
      final response = await _dio.get<dynamic>(
        'http://$host:$port/api/tags',
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

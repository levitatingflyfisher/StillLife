import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';

class WebDavConfig {
  final String url;
  final String? username;
  final String? password;

  const WebDavConfig({required this.url, this.username, this.password});
}

/// Backs up and restores the Still Life JSON export to/from a WebDAV server.
///
/// Uses Dio for HTTP so no new dependency is required. Supports basic auth.
/// The backup file is stored at [url] exactly as supplied — typically something
/// like `https://nextcloud.example.com/remote.php/dav/files/alice/still_life_backup.json`.
class WebDavBackupService {
  static const _urlKey = 'webdav_url';
  static const _userKey = 'webdav_user';
  static const _passKey = 'webdav_pass';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  WebDavBackupService({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage();

  // ── Config persistence ───────────────────────────────────────────────────

  Future<WebDavConfig?> loadConfig() async {
    final url = await _storage.read(key: _urlKey);
    if (url == null || url.isEmpty) return null;
    return WebDavConfig(
      url: url,
      username: await _storage.read(key: _userKey),
      password: await _storage.read(key: _passKey),
    );
  }

  Future<void> saveConfig(WebDavConfig config) async {
    await _storage.write(key: _urlKey, value: config.url);
    await _storage.write(key: _userKey, value: config.username ?? '');
    await _storage.write(key: _passKey, value: config.password ?? '');
  }

  Future<void> clearConfig() async {
    await _storage.delete(key: _urlKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _passKey);
  }

  // ── Backup / Restore ─────────────────────────────────────────────────────

  /// PUT [jsonData] to the configured WebDAV URL.
  ///
  /// Returns [Err] with [SecurityFailure] if the configured URL is not
  /// HTTPS — Basic Auth over plaintext HTTP would leak credentials.
  /// Throws [StateError] if WebDAV is not configured.
  Future<Result<void>> backup(String jsonData) async {
    final cfg = await loadConfig();
    if (cfg == null) throw StateError('WebDAV not configured');

    if (!cfg.url.startsWith('https://')) {
      final scheme = cfg.url.contains('://')
          ? cfg.url.split('://').first
          : 'unknown';
      return Err(SecurityFailure('WebDAV URL must use HTTPS (got $scheme).'));
    }

    await _dio.put<void>(
      cfg.url,
      data: Stream.fromIterable([utf8.encode(jsonData)]),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          if (cfg.username != null && cfg.username!.isNotEmpty)
            'Authorization': _basicAuth(cfg.username!, cfg.password ?? ''),
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return const Success(null);
  }

  /// GET the backup JSON from the configured WebDAV URL.
  ///
  /// Returns [Err] with [SecurityFailure] if the configured URL is not
  /// HTTPS. Throws [StateError] if WebDAV is not configured or the server
  /// returns an empty body.
  Future<Result<String>> restore() async {
    final cfg = await loadConfig();
    if (cfg == null) throw StateError('WebDAV not configured');

    if (!cfg.url.startsWith('https://')) {
      final scheme = cfg.url.contains('://')
          ? cfg.url.split('://').first
          : 'unknown';
      return Err(SecurityFailure('WebDAV URL must use HTTPS (got $scheme).'));
    }

    final response = await _dio.get<String>(
      cfg.url,
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          if (cfg.username != null && cfg.username!.isNotEmpty)
            'Authorization': _basicAuth(cfg.username!, cfg.password ?? ''),
        },
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    if (response.data == null) throw StateError('Empty response from server');
    return Success(response.data!);
  }

  String _basicAuth(String user, String pass) {
    final encoded = base64Encode(utf8.encode('$user:$pass'));
    return 'Basic $encoded';
  }
}

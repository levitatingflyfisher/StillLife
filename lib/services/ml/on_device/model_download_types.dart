/// Platform-free download types — settings UI (which also compiles for
/// web) needs these without touching the dart:io downloader.
library;

/// Verification or transport failure — the download failed closed and
/// nothing was installed.
class ModelDownloadException implements Exception {
  final String message;
  const ModelDownloadException(this.message);
  @override
  String toString() => 'ModelDownloadException: $message';
}

/// The user cancelled; partial files were cleaned up.
class ModelDownloadCancelled implements Exception {}

/// Cooperative cancellation flag checked between stream chunks.
class ModelDownloadToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

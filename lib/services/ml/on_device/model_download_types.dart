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

/// The user cancelled. The partial file is deliberately kept, so pressing
/// download again resumes from the byte it stopped at rather than paying
/// for the whole artifact a second time.
class ModelDownloadCancelled implements Exception {}

/// Cooperative cancellation flag for an in-flight download.
class ModelDownloadToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Runs [listener] when the token fires (immediately if it already has).
  ///
  /// Polling alone was never enough: a download that has stalled delivers
  /// no more bytes, so nothing would ever look at the flag and the cancel
  /// button would hang until the connection timed out.
  void whenCancelled(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}

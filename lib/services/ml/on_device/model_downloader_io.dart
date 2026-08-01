import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:domovoi/domovoi.dart' as domovoi;
import 'package:still_life/services/ml/on_device/model_download_types.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/model_store_io.dart';

export 'package:still_life/services/ml/on_device/model_download_types.dart';

/// Downloads a model's artifacts with fail-closed integrity: each file is
/// transferred to a `.part` sibling, then its size and sha256 are checked
/// against the commit-pinned registry values before the atomic rename into
/// place. Any mismatch throws and installs nothing — a corrupted or
/// substituted artifact can never become the model the app loads.
///
/// The transfer itself is domovoi's, the fleet's one resumable engine: an
/// interrupted attempt leaves its partial behind and the next one asks for
/// the byte it stopped at. That matters here more than anywhere — these
/// are GB-scale files landing on a phone that sleeps, and restarting from
/// zero at 90% is how a download becomes a thing the user gives up on.
/// Files already present at their exact size are skipped, so a re-run also
/// resumes at whole-file granularity.
class IoModelDownloader {
  final IoOnDeviceModelStore store;

  /// The transfer client. Model files are GB-scale, so the caller's
  /// client is configured without a receive timeout.
  final Dio dio;

  IoModelDownloader({required this.store, required this.dio});

  Future<void> download(
    OnDeviceModel model, {
    void Function(double fraction)? onProgress,
    ModelDownloadToken? token,
  }) async {
    final total = model.totalBytes;
    var done = 0;
    var shown = 0.0;

    // A high-water mark, because the byte counts underneath are not
    // monotonic: the engine restarts a file from zero when the host
    // ignores a Range request or answers 416. A progress bar that jumps
    // backwards reads as a fault the download does not have.
    void report(double fraction) {
      if (fraction > shown) shown = fraction;
      onProgress?.call(shown);
    }

    // One dio token for the whole model: the app's flag is a plain
    // boolean, the engine wants something it can interrupt a socket with.
    final cancelToken = CancelToken();
    token?.whenCancelled(() => cancelToken.cancel());

    for (final f in model.files) {
      final path = await store.filePath(model, f);
      final file = File(path);
      if (await file.exists() && await file.length() == f.sizeBytes) {
        done += f.sizeBytes;
        report(done / total);
        continue;
      }

      final part = File('$path.part');
      final at = done;

      final domovoi.TransferOutcome outcome;
      try {
        outcome = await domovoi.resumableDownload(
          dio: dio,
          url: f.url,
          partFile: part,
          cancelToken: cancelToken,
          onProgress: (received, _) {
            // Never count more of this file than the registry pins it at.
            // A resume the host answers with the WHOLE file reports past
            // the pinned size, and an uncapped overshoot would be frozen
            // into the high-water mark above — a bar stuck at 100% while
            // the transfer is really starting over.
            final counted = received > f.sizeBytes ? f.sizeBytes : received;
            report((at + counted) / total);
          },
          promote: () async => _verifyAndInstall(f, part, path),
        );
      } on ModelDownloadException {
        // Already named and already cleaned up by the verifier.
        rethrow;
      } catch (e) {
        // The partial is left exactly where it is. A dropped connection at
        // 90% of a 1.1 GB model used to cost the whole file again; now the
        // next attempt asks for the byte it stopped at.
        throw ModelDownloadException('${f.filename}: $e');
      }

      // A cancelled run ends the engine's future NORMALLY. Letting that
      // through would return from download() as if it had succeeded, and
      // the settings screen would show a half-transferred model as
      // installed. Cancellation is an outcome to be raised, not silence.
      if (outcome == domovoi.TransferOutcome.cancelled) {
        throw ModelDownloadCancelled();
      }

      done += f.sizeBytes;
      report(done / total);
    }
  }

  /// The post-transfer half: check the artifact on disk against the
  /// commit-pinned registry values, then rename it into place. Verification
  /// reads the finished `.part` rather than hashing the wire, because under
  /// a resume the early bytes arrived during some earlier attempt and were
  /// never in this stream at all.
  Future<void> _verifyAndInstall(
    OnDeviceModelFile f,
    File part,
    String path,
  ) async {
    final size = await part.length();
    if (size != f.sizeBytes) {
      await _discard(part);
      throw ModelDownloadException(
        '${f.filename}: got $size bytes, expected ${f.sizeBytes} — '
        'refusing to install a truncated model.',
      );
    }

    final digest = await sha256.bind(part.openRead()).first;
    if (digest.toString() != f.sha256) {
      await _discard(part);
      throw ModelDownloadException(
        '${f.filename}: sha256 mismatch — the artifact does not match '
        'the pinned release; refusing to install it.',
      );
    }

    await part.rename(path);
  }

  /// Throws away bytes that failed verification. A transport error keeps
  /// its partial — that is what makes the next attempt cheap — but bytes
  /// the hash rejected are the one thing a resume must never append to:
  /// every later attempt would inherit the corruption and fail forever.
  Future<void> _discard(File part) async {
    if (await part.exists()) await part.delete();
  }
}

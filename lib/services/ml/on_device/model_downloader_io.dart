import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:still_life/services/ml/on_device/model_download_types.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/model_store_io.dart';

export 'package:still_life/services/ml/on_device/model_download_types.dart';

/// Fetches a URL as a byte stream. Injected so the download/verify logic
/// is testable without HTTP; the real implementation wraps dio.
typedef ByteStreamFetcher = Stream<List<int>> Function(String url);

/// Downloads a model's artifacts with fail-closed integrity: each file
/// streams to a `.part` sibling while a sha256 accumulates, then size and
/// hash are checked against the commit-pinned registry values before the
/// atomic rename into place. Any mismatch deletes the partial and throws —
/// a corrupted or substituted artifact can never be installed.
///
/// Files already present at their exact size are skipped, so re-running
/// after a failure resumes at file granularity.
class IoModelDownloader {
  final IoOnDeviceModelStore store;
  final ByteStreamFetcher fetch;

  IoModelDownloader({required this.store, required this.fetch});

  Future<void> download(
    OnDeviceModel model, {
    void Function(double fraction)? onProgress,
    ModelDownloadToken? token,
  }) async {
    final total = model.totalBytes;
    var done = 0;

    for (final f in model.files) {
      final path = await store.filePath(model, f);
      final file = File(path);
      if (await file.exists() && await file.length() == f.sizeBytes) {
        done += f.sizeBytes;
        onProgress?.call(done / total);
        continue;
      }

      final part = File('$path.part');
      await part.create(recursive: true);
      final sink = part.openWrite();
      final hashOut = _DigestSink();
      final hashIn = sha256.startChunkedConversion(hashOut);
      var received = 0;

      try {
        await for (final chunk in fetch(f.url)) {
          if (token?.isCancelled ?? false) {
            throw ModelDownloadCancelled();
          }
          sink.add(chunk);
          hashIn.add(chunk);
          received += chunk.length;
          onProgress?.call((done + received) / total);
        }
        await sink.flush();
        await sink.close();
        hashIn.close();

        if (received != f.sizeBytes) {
          throw ModelDownloadException(
            '${f.filename}: got $received bytes, expected ${f.sizeBytes} — '
            'refusing to install a truncated model.',
          );
        }
        final digest = hashOut.digest.toString();
        if (digest != f.sha256) {
          throw ModelDownloadException(
            '${f.filename}: sha256 mismatch — the artifact does not match '
            'the pinned release; refusing to install it.',
          );
        }

        await part.rename(path);
        done += f.sizeBytes;
        onProgress?.call(done / total);
      } catch (e) {
        try {
          await sink.close();
        } catch (_) {}
        if (await part.exists()) {
          await part.delete();
        }
        if (e is ModelDownloadCancelled || e is ModelDownloadException) {
          rethrow;
        }
        throw ModelDownloadException('${f.filename}: $e');
      }
    }
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest digest;
  @override
  void add(Digest data) => digest = data;
  @override
  void close() {}
}

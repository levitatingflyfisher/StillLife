import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/on_device/model_downloader_io.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/model_store_io.dart';

/// Deterministic bodies, KB-scale: the downloader now talks to a real
/// server over loopback, and a body small enough to arrive in one chunk
/// could never exercise mid-flight cancel or a byte-offset resume.
final _bodyA = List<int>.generate(4096, (i) => i % 251);
final _bodyB = List<int>.generate(1024, (i) => (i * 7) % 251);

List<int> _bodyFor(String path) =>
    path.endsWith('mmproj-model.gguf') ? _bodyB : _bodyA;

OnDeviceModel _model(int port) => OnDeviceModel(
  id: 'test-model',
  displayName: 'Test Model',
  license: 'Apache-2.0',
  sourceRepo: 'example/test',
  ramNote: '~1 GB RAM',
  files: [
    OnDeviceModelFile(
      filename: 'model.gguf',
      url: 'http://127.0.0.1:$port/model.gguf',
      sizeBytes: _bodyA.length,
      sha256: sha256.convert(_bodyA).toString(),
    ),
    OnDeviceModelFile(
      filename: 'mmproj-model.gguf',
      url: 'http://127.0.0.1:$port/mmproj-model.gguf',
      sizeBytes: _bodyB.length,
      sha256: sha256.convert(_bodyB).toString(),
    ),
  ],
);

void main() {
  late Directory tempDir;
  late IoOnDeviceModelStore store;
  late Dio dio;
  HttpServer? server;

  setUp(() async {
    // The Flutter test binding stubs every HttpClient into a canned 400 so
    // stray widget code cannot reach the network. Here the loopback server
    // IS the subject: without this the transfer never leaves the process.
    HttpOverrides.global = null;
    tempDir = await Directory.systemTemp.createTemp('model_dl_test');
    store = IoOnDeviceModelStore(resolveBaseDir: () async => tempDir.path);
    dio = Dio();
  });

  tearDown(() async {
    await server?.close(force: true);
    server = null;
    dio.close(force: true);
    await tempDir.delete(recursive: true);
  });

  /// A loopback origin, so the transfer is exercised against a real server:
  /// the engine's contract is written in Range, 206 and 416, none of which
  /// an injected byte stream can speak. Returns the port to build URLs from.
  Future<int> serve(void Function(HttpRequest req) handler) async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen(handler);
    return server!.port;
  }

  /// The plain case: whole body, correct length, no Range handling.
  Future<int> serveWhole({List<String>? requested}) => serve((req) async {
    requested?.add(req.uri.path);
    final body = _bodyFor(req.uri.path);
    req.response
      ..statusCode = HttpStatus.ok
      ..contentLength = body.length
      ..add(body);
    await req.response.close();
  });

  List<FileSystemEntity> partsOf(String modelId) {
    final dir = Directory('${tempDir.path}/$modelId');
    return dir.existsSync()
        ? dir.listSync().where((e) => e.path.contains('.part')).toList()
        : const [];
  }

  group('IoModelDownloader', () {
    test('downloads every file, installs atomically (.part rename), '
        'progress is monotonic and ends at 1.0', () async {
      final requested = <String>[];
      final progress = <double>[];
      final model = _model(await serveWhole(requested: requested));
      final dl = IoModelDownloader(store: store, dio: dio);

      await dl.download(model, onProgress: progress.add);

      expect(await store.isDownloaded(model), isTrue);
      final installed = File('${tempDir.path}/test-model/model.gguf');
      expect(await installed.readAsBytes(), _bodyA);
      expect(partsOf('test-model'), isEmpty);
      expect(requested, ['/model.gguf', '/mmproj-model.gguf']);
      expect(progress.last, 1.0);
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
      }
    });

    test('a truncated body fails closed: throws, installs nothing', () async {
      // Short body AND a matching Content-Length, so the transfer itself
      // succeeds — only the pinned size says the artifact is wrong.
      final port = await serve((req) async {
        final short = _bodyFor(req.uri.path).sublist(0, 100);
        req.response
          ..statusCode = HttpStatus.ok
          ..contentLength = short.length
          ..add(short);
        await req.response.close();
      });
      final model = _model(port);

      await expectLater(
        IoModelDownloader(store: store, dio: dio).download(model),
        throwsA(isA<ModelDownloadException>()),
      );
      expect(await store.isDownloaded(model), isFalse);
      expect(File('${tempDir.path}/test-model/model.gguf').existsSync(),
          isFalse);
    });

    test('a substituted body of the right length fails closed on sha256, '
        'and the message names the file', () async {
      // Right size, wrong bytes: the only thing standing between the user
      // and a swapped artifact is the pinned hash.
      final port = await serve((req) async {
        final body = List<int>.filled(_bodyFor(req.uri.path).length, 0x42);
        req.response
          ..statusCode = HttpStatus.ok
          ..contentLength = body.length
          ..add(body);
        await req.response.close();
      });
      final model = _model(port);

      await expectLater(
        IoModelDownloader(store: store, dio: dio).download(model),
        throwsA(
          isA<ModelDownloadException>().having(
            (e) => e.message,
            'message',
            allOf(contains('sha256'), contains('model.gguf')),
          ),
        ),
      );
      expect(await store.isDownloaded(model), isFalse);
      expect(File('${tempDir.path}/test-model/model.gguf').existsSync(),
          isFalse);
    });

    test('a verification failure deletes the .part — bytes that failed the '
        'hash must never be resumed onto', () async {
      final port = await serve((req) async {
        final body = List<int>.filled(_bodyFor(req.uri.path).length, 0x42);
        req.response
          ..statusCode = HttpStatus.ok
          ..contentLength = body.length
          ..add(body);
        await req.response.close();
      });

      await expectLater(
        IoModelDownloader(store: store, dio: dio).download(_model(port)),
        throwsA(isA<ModelDownloadException>()),
      );
      expect(partsOf('test-model'), isEmpty);
    });

    test('cancellation throws ModelDownloadCancelled, keeps the .part for '
        'resume, and never reaches the next file', () async {
      final gate = Completer<void>();
      final requested = <String>[];
      final port = await serve((req) async {
        requested.add(req.uri.path);
        final body = _bodyFor(req.uri.path);
        req.response
          // dart:io buffers ~8KB by default; the prefix must actually reach
          // the wire or the client never sees mid-flight progress.
          ..bufferOutput = false
          ..statusCode = HttpStatus.ok
          ..contentLength = body.length
          ..add(body.sublist(0, 1024));
        await req.response.flush();
        try {
          await gate.future;
          await req.response.close();
        } catch (_) {}
      });
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });

      final model = _model(port);
      final token = ModelDownloadToken();

      // A quiet return here is the failure that matters: the controller
      // would announce a half-downloaded 1.1 GB model as installed.
      await expectLater(
        IoModelDownloader(store: store, dio: dio).download(
          model,
          token: token,
          onProgress: (_) {
            if (!token.isCancelled) token.cancel();
          },
        ),
        throwsA(isA<ModelDownloadCancelled>()),
      );

      expect(requested, ['/model.gguf']);
      expect(await store.isDownloaded(model), isFalse);
      // The partial is deliberately KEPT — resuming it is the whole point.
      final part = File('${tempDir.path}/test-model/model.gguf.part');
      expect(part.existsSync(), isTrue);
      expect(part.lengthSync(), lessThan(_bodyA.length));
    });

    test('a host that ignores Range makes the engine restart the file; the '
        'aggregate fraction still never goes backwards or past 1.0', () async {
      // A partial from an earlier attempt, and a server that answers the
      // Range with a plain 200. The engine throws the partial away and
      // starts over — so the raw byte count reported to us drops back to
      // zero mid-file, twice over the same bytes.
      final part = File('${tempDir.path}/test-model/model.gguf.part');
      await part.create(recursive: true);
      await part.writeAsBytes(_bodyA.sublist(0, 2000));

      final progress = <double>[];
      final model = _model(await serveWhole());

      await IoModelDownloader(store: store, dio: dio)
          .download(model, onProgress: progress.add);

      expect(await store.isDownloaded(model), isTrue);
      expect(progress, everyElement(lessThanOrEqualTo(1.0)));
      // Not a bar pinned at 100% either: swallowing the overshoot into the
      // high-water mark would satisfy "monotonic, ends at 1.0" while the
      // user watches a full bar through an entire re-download.
      expect(progress.first, lessThan(1.0),
          reason: 'the first report already claims the whole model: $progress');
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]),
            reason: 'progress went backwards at index $i: $progress');
      }
      expect(progress.last, 1.0);
    });

    test('a dropped transfer surfaces as ModelDownloadException and KEEPS '
        'its .part; the retry resumes from that byte, not from zero',
        () async {
      final ranges = <String?>[];
      var attempts = 0;
      final port = await serve((req) async {
        final body = _bodyFor(req.uri.path);
        final range = req.headers.value(HttpHeaders.rangeHeader);
        ranges.add(range);

        if (req.uri.path == '/model.gguf' && attempts++ == 0) {
          // The phone sleeps, the tower drops it: bytes stop mid-file.
          // Written straight to the socket because dart:io will not let a
          // well-behaved HttpResponse promise a length and then renege.
          final socket = await req.response.detachSocket(writeHeaders: false);
          socket.add(utf8.encode('HTTP/1.1 200 OK\r\n'
              'Content-Length: ${body.length}\r\n\r\n'));
          socket.add(body.sublist(0, 2000));
          await socket.flush();
          await socket.close();
          return;
        }

        if (range != null) {
          final from = int.parse(range.split('=')[1].split('-')[0]);
          final rest = body.sublist(from);
          req.response
            ..statusCode = HttpStatus.partialContent
            ..contentLength = rest.length
            ..headers.set(HttpHeaders.contentRangeHeader,
                'bytes $from-${body.length - 1}/${body.length}')
            ..add(rest);
          await req.response.close();
          return;
        }

        req.response
          ..statusCode = HttpStatus.ok
          ..contentLength = body.length
          ..add(body);
        await req.response.close();
      });

      final model = _model(port);
      final dl = IoModelDownloader(store: store, dio: dio);

      await expectLater(
        dl.download(model),
        throwsA(
          isA<ModelDownloadException>()
              .having((e) => e.message, 'message', contains('model.gguf')),
        ),
      );
      final part = File('${tempDir.path}/test-model/model.gguf.part');
      expect(part.lengthSync(), 2000,
          reason: 'the partial is what makes the retry cheap');

      await dl.download(model);

      expect(await store.isDownloaded(model), isTrue);
      // The second attempt asked for byte 2000 onward: 1.1 GB of already
      // transferred bytes is not paid for twice.
      expect(ranges, [null, 'bytes=2000-', null]);
      expect(
        await File('${tempDir.path}/test-model/model.gguf').readAsBytes(),
        _bodyA,
      );
    });

    test('files already present at their exact size are skipped — a re-run '
        'after one file failed picks up where it left off', () async {
      final requested = <String>[];
      final port = await serveWhole(requested: requested);
      final model = _model(port);
      final installed = File('${tempDir.path}/test-model/model.gguf');
      await installed.create(recursive: true);
      await installed.writeAsBytes(_bodyA);

      await IoModelDownloader(store: store, dio: dio).download(model);

      expect(requested, ['/mmproj-model.gguf']);
      expect(await store.isDownloaded(model), isTrue);
    });
  });
}

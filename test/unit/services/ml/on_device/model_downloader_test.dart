import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/on_device/model_downloader_io.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/model_store_io.dart';

final _bodyA = utf8.encode('GGUFaaaa'); // 8 bytes
final _bodyB = utf8.encode('GGUF'); // 4 bytes

OnDeviceModel _model() => OnDeviceModel(
  id: 'test-model',
  displayName: 'Test Model',
  license: 'Apache-2.0',
  sourceRepo: 'example/test',
  ramNote: '~1 GB RAM',
  files: [
    OnDeviceModelFile(
      filename: 'model.gguf',
      url: 'https://example.invalid/a/model.gguf',
      sizeBytes: _bodyA.length,
      sha256: sha256.convert(_bodyA).toString(),
    ),
    OnDeviceModelFile(
      filename: 'mmproj-model.gguf',
      url: 'https://example.invalid/a/mmproj-model.gguf',
      sizeBytes: _bodyB.length,
      sha256: sha256.convert(_bodyB).toString(),
    ),
  ],
);

void main() {
  late Directory tempDir;
  late IoOnDeviceModelStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('model_dl_test');
    store = IoOnDeviceModelStore(resolveBaseDir: () async => tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('IoModelDownloader', () {
    test('downloads every file, verifies size+sha256, installs atomically '
        '(.part rename), progress is monotonic and ends at 1.0', () async {
      final fetched = <String>[];
      final progress = <double>[];
      final dl = IoModelDownloader(
        store: store,
        fetch: (url) {
          fetched.add(url);
          final body = url.endsWith('mmproj-model.gguf') ? _bodyB : _bodyA;
          // Two chunks so progress ticks mid-file.
          return Stream.fromIterable([
            body.sublist(0, 2),
            body.sublist(2),
          ]);
        },
      );

      await dl.download(_model(), onProgress: progress.add);

      expect(await store.isDownloaded(_model()), isTrue);
      final installed = File('${tempDir.path}/test-model/model.gguf');
      expect(await installed.readAsBytes(), _bodyA);
      expect(
        Directory('${tempDir.path}/test-model')
            .listSync()
            .where((e) => e.path.endsWith('.part')),
        isEmpty,
      );
      expect(fetched, hasLength(2));
      expect(progress.last, 1.0);
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
      }
    });

    test('a corrupted stream (sha mismatch) fails closed: throws, installs '
        'nothing, leaves no .part behind', () async {
      final dl = IoModelDownloader(
        store: store,
        fetch: (_) => Stream.value(utf8.encode('GGUFxxxx')), // wrong bytes
      );

      await expectLater(
        dl.download(_model()),
        throwsA(isA<ModelDownloadException>()),
      );
      expect(await store.isDownloaded(_model()), isFalse);
      final dir = Directory('${tempDir.path}/test-model');
      expect(
        dir.existsSync()
            ? dir.listSync().where((e) => e.path.contains('.part'))
            : const <Never>[],
        isEmpty,
      );
    });

    test('a truncated stream (size mismatch) also fails closed', () async {
      final dl = IoModelDownloader(
        store: store,
        fetch: (_) => Stream.value(_bodyA.sublist(0, 5)),
      );
      await expectLater(
        dl.download(_model()),
        throwsA(isA<ModelDownloadException>()),
      );
      expect(await store.isDownloaded(_model()), isFalse);
    });

    test('cancellation between chunks stops the download, cleans the .part, '
        'and never fetches the next file', () async {
      final token = ModelDownloadToken();
      final fetched = <String>[];
      final dl = IoModelDownloader(
        store: store,
        fetch: (url) async* {
          fetched.add(url);
          yield _bodyA.sublist(0, 2);
          token.cancel();
          yield _bodyA.sublist(2);
        },
      );

      await expectLater(
        dl.download(_model(), token: token),
        throwsA(isA<ModelDownloadCancelled>()),
      );
      expect(fetched, ['https://example.invalid/a/model.gguf']);
      expect(await store.isDownloaded(_model()), isFalse);
      final dir = Directory('${tempDir.path}/test-model');
      expect(
        dir.existsSync()
            ? dir.listSync().where((e) => e.path.contains('.part'))
            : const <Never>[],
        isEmpty,
      );
    });

    test('files already present at their exact size are skipped — '
        'a re-download after one file failed picks up where it left off',
        () async {
      final model = _model();
      final existing = File('${tempDir.path}/test-model/model.gguf');
      await existing.create(recursive: true);
      await existing.writeAsBytes(_bodyA);

      final fetched = <String>[];
      final dl = IoModelDownloader(
        store: store,
        fetch: (url) {
          fetched.add(url);
          return Stream.value(_bodyB);
        },
      );

      await dl.download(model);

      expect(fetched, ['https://example.invalid/a/mmproj-model.gguf']);
      expect(await store.isDownloaded(model), isTrue);
    });
  });
}

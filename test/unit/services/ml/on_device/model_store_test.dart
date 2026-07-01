import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/model_store_io.dart';

const _model = OnDeviceModel(
  id: 'test-model',
  displayName: 'Test Model',
  license: 'Apache-2.0',
  sourceRepo: 'example/test',
  ramNote: '~1 GB RAM',
  files: [
    OnDeviceModelFile(
      filename: 'model.gguf',
      url: 'https://example.invalid/resolve/'
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/model.gguf',
      sizeBytes: 8,
      sha256:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
          'aaaaaaaaaaaaaaaaaaaaaaaa',
    ),
    OnDeviceModelFile(
      filename: 'mmproj-model.gguf',
      url: 'https://example.invalid/resolve/'
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/mmproj-model.gguf',
      sizeBytes: 4,
      sha256:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
          'aaaaaaaaaaaaaaaaaaaaaaaa',
    ),
  ],
);

void main() {
  late Directory tempDir;
  late IoOnDeviceModelStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('model_store_test');
    store = IoOnDeviceModelStore(resolveBaseDir: () async => tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<void> writeFile(String name, int bytes) async {
    final f = File('${tempDir.path}/test-model/$name');
    await f.create(recursive: true);
    await f.writeAsBytes(List.filled(bytes, 7));
  }

  group('IoOnDeviceModelStore', () {
    test('isDownloaded is false when nothing exists', () async {
      expect(await store.isDownloaded(_model), isFalse);
    });

    test('isDownloaded is false when a file is missing', () async {
      await writeFile('model.gguf', 8);
      expect(await store.isDownloaded(_model), isFalse);
    });

    test('isDownloaded is false when a file has the wrong size — a '
        'truncated download must never count as installed', () async {
      await writeFile('model.gguf', 5); // want 8
      await writeFile('mmproj-model.gguf', 4);
      expect(await store.isDownloaded(_model), isFalse);
    });

    test('isDownloaded is true when every file exists at its exact size',
        () async {
      await writeFile('model.gguf', 8);
      await writeFile('mmproj-model.gguf', 4);
      expect(await store.isDownloaded(_model), isTrue);
    });

    test('filePath points inside the per-model directory', () async {
      final p = await store.filePath(_model, _model.files.first);
      expect(p, '${tempDir.path}/test-model/model.gguf');
    });

    test('delete removes the whole model directory', () async {
      await writeFile('model.gguf', 8);
      await writeFile('mmproj-model.gguf', 4);
      await store.delete(_model);
      expect(await store.isDownloaded(_model), isFalse);
      expect(Directory('${tempDir.path}/test-model').existsSync(), isFalse);
    });

    test('delete of a never-downloaded model is a quiet no-op', () async {
      await store.delete(_model);
    });
  });
}

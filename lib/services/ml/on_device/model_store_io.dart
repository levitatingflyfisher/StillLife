import 'dart:io';

import 'package:still_life/services/ml/on_device/model_registry.dart';

/// Where downloaded on-device models live on disk and whether they are
/// complete. dart:io — never imported on web (the on-device tier's io/stub
/// trio guards every import path).
///
/// "Downloaded" = every file of the model exists at its exact registry
/// byte size. Sizes are cheap enough to check on every availability probe;
/// the expensive sha256 verification happens once, at download time.
class IoOnDeviceModelStore {
  /// Resolves the base directory that holds one subdirectory per model id
  /// (injected: real wiring uses the app documents dir, tests a temp dir).
  final Future<String> Function() resolveBaseDir;

  IoOnDeviceModelStore({required this.resolveBaseDir});

  Future<String> _modelDir(OnDeviceModel model) async =>
      '${await resolveBaseDir()}/${model.id}';

  /// Absolute path of one artifact of [model].
  Future<String> filePath(OnDeviceModel model, OnDeviceModelFile file) async =>
      '${await _modelDir(model)}/${file.filename}';

  /// True when every artifact exists at its exact pinned size — a
  /// truncated download never counts as installed.
  Future<bool> isDownloaded(OnDeviceModel model) async {
    for (final f in model.files) {
      final file = File(await filePath(model, f));
      if (!await file.exists()) return false;
      if (await file.length() != f.sizeBytes) return false;
    }
    return true;
  }

  /// The first fully-downloaded model in registry (recommendation) order,
  /// or null when none is installed.
  Future<OnDeviceModel?> firstDownloaded() async {
    for (final model in kOnDeviceModels) {
      if (await isDownloaded(model)) return model;
    }
    return null;
  }

  /// Removes the model's directory (quiet no-op when absent).
  Future<void> delete(OnDeviceModel model) async {
    final dir = Directory(await _modelDir(model));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

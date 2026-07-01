/// The catalogue of on-device VLM models the app can download (rung 1.5).
///
/// Every artifact is commit-pinned (the `/resolve/<40-hex-sha>/` URL form)
/// with its exact byte size and sha256, verified against the live
/// Hugging Face artifacts on 2026-07-16 — a moved or replaced upstream
/// file fails verification instead of installing. Both models are
/// first-party ggml-org conversions under Apache-2.0, so the weights are
/// FLOSS-clean for an MIT app. Downloads are always user-initiated.
library;

/// One downloadable artifact of a model (text model or mmproj projector).
class OnDeviceModelFile {
  final String filename;
  final String url;
  final int sizeBytes;
  final String sha256;

  const OnDeviceModelFile({
    required this.filename,
    required this.url,
    required this.sizeBytes,
    required this.sha256,
  });
}

/// A downloadable on-device vision-language model.
class OnDeviceModel {
  final String id;
  final String displayName;
  final String license;

  /// Hugging Face repo, for settings UI and docs provenance.
  final String sourceRepo;

  /// Human-readable RAM guidance shown before download.
  final String ramNote;

  final List<OnDeviceModelFile> files;

  const OnDeviceModel({
    required this.id,
    required this.displayName,
    required this.license,
    required this.sourceRepo,
    required this.ramNote,
    required this.files,
  });

  int get totalBytes => files.fold(0, (sum, f) => sum + f.sizeBytes);

  OnDeviceModelFile get mmprojFile =>
      files.firstWhere((f) => f.filename.startsWith('mmproj-'));

  OnDeviceModelFile get textModelFile =>
      files.firstWhere((f) => !f.filename.startsWith('mmproj-'));
}

const String _repo22 = 'ggml-org/SmolVLM2-2.2B-Instruct-GGUF';
const String _rev22 = '1bc3c9f74ceafd4c8d4411cc9cf188bba3798f91';
const String _repo05 = 'ggml-org/SmolVLM2-500M-Video-Instruct-GGUF';
const String _rev05 = 'ccd7aae53bcb1997355c2f094959e72b3642ce17';

/// Registry order = recommendation order; the first entry is the default
/// offered in settings, and the engine loads the first downloaded model.
const List<OnDeviceModel> kOnDeviceModels = [
  OnDeviceModel(
    id: 'smolvlm2-2.2b',
    displayName: 'SmolVLM2 2.2B (recommended)',
    license: 'Apache-2.0',
    sourceRepo: _repo22,
    ramNote: '~2.5 GB RAM while analyzing — needs a 6 GB+ phone',
    files: [
      OnDeviceModelFile(
        filename: 'SmolVLM2-2.2B-Instruct-Q4_K_M.gguf',
        url: 'https://huggingface.co/$_repo22/resolve/$_rev22/'
            'SmolVLM2-2.2B-Instruct-Q4_K_M.gguf',
        sizeBytes: 1112602656,
        sha256:
            '0cf76814555b8665149075b74ab6b5c1d428ea1d3d01c1918c12012e8d7c9f58',
      ),
      OnDeviceModelFile(
        filename: 'mmproj-SmolVLM2-2.2B-Instruct-Q8_0.gguf',
        url: 'https://huggingface.co/$_repo22/resolve/$_rev22/'
            'mmproj-SmolVLM2-2.2B-Instruct-Q8_0.gguf',
        sizeBytes: 592523200,
        sha256:
            'ae07ea1facd07dd3230c4483b63e8cda96c6944ad2481f33d531f79e892dd024',
      ),
    ],
  ),
  OnDeviceModel(
    id: 'smolvlm2-500m',
    displayName: 'SmolVLM2 500M (lite)',
    license: 'Apache-2.0',
    sourceRepo: _repo05,
    ramNote: '~1 GB RAM while analyzing — fits most phones',
    files: [
      OnDeviceModelFile(
        filename: 'SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
        url: 'https://huggingface.co/$_repo05/resolve/$_rev05/'
            'SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
        sizeBytes: 436808704,
        sha256:
            '6f67b8036b2469fcd71728702720c6b51aebd759b78137a8120733b4d66438bc',
      ),
      OnDeviceModelFile(
        filename: 'mmproj-SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
        url: 'https://huggingface.co/$_repo05/resolve/$_rev05/'
            'mmproj-SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
        sizeBytes: 108785184,
        sha256:
            '921dc7e259f308e5b027111fa185efcbf33db13f6e35749ddf7f5cdb60ef520b',
      ),
    ],
  ),
];

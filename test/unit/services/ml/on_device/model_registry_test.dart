import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';

void main() {
  group('kOnDeviceModels registry', () {
    test('offers the 2.2B default first, then the 500M lite option', () {
      expect(kOnDeviceModels, hasLength(2));
      expect(kOnDeviceModels.first.id, 'smolvlm2-2.2b');
      expect(kOnDeviceModels.last.id, 'smolvlm2-500m');
    });

    test('every file is commit-pinned with exact size and sha256 — a moved '
        'or replaced upstream artifact must fail verification, not install',
        () {
      for (final model in kOnDeviceModels) {
        expect(model.files, hasLength(2),
            reason: 'GGUF text model + mmproj vision projector');
        for (final f in model.files) {
          expect(f.url, startsWith('https://huggingface.co/ggml-org/'));
          expect(
            f.url,
            matches(RegExp(r'/resolve/[0-9a-f]{40}/')),
            reason: 'URL pins a commit, never a movable branch ref',
          );
          expect(f.sizeBytes, greaterThan(1000000));
          expect(f.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
          expect(f.url, endsWith(f.filename));
        }
      }
    });

    test('total download sizes match the verified artifacts', () {
      final big = kOnDeviceModels.first;
      final lite = kOnDeviceModels.last;
      expect(big.totalBytes, 1112602656 + 592523200); // ≈1.71 GB
      expect(lite.totalBytes, 436808704 + 108785184); // ≈0.55 GB
    });

    test('licenses are recorded — both models are Apache-2.0', () {
      for (final model in kOnDeviceModels) {
        expect(model.license, 'Apache-2.0');
      }
    });

    test('mmproj file is distinguishable from the text model file', () {
      for (final model in kOnDeviceModels) {
        expect(
          model.files.where((f) => f.filename.startsWith('mmproj-')),
          hasLength(1),
        );
        expect(model.mmprojFile.filename, startsWith('mmproj-'));
        expect(model.textModelFile.filename, isNot(startsWith('mmproj-')));
      }
    });
  });
}

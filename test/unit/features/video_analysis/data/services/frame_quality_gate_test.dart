import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/data/services/frame_quality_gate.dart';
import 'package:still_life/features/video_analysis/domain/entities/frame_data.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

FrameData _frame({
  required int index,
  required double sharpness,
  String? hash,
}) => FrameData(
  index: index,
  timestamp: index / 2.0,
  imageBytes: Uint8List.fromList([index]),
  width: 8,
  height: 8,
  sharpness: sharpness,
  perceptualHash: hash,
);

void main() {
  const gate = FrameQualityGate();

  group('AnalysisConfig.topKFrames', () {
    test('defaults to 12 analysis frames', () {
      expect(const AnalysisConfig().topKFrames, 12);
    });
  });

  group('FrameQualityGate', () {
    test('drops frames below the blur threshold', () {
      final frames = [
        _frame(index: 0, sharpness: 250.0, hash: '0000000000000000'),
        _frame(index: 1, sharpness: 20.0, hash: 'ffffffffffffffff'),
        _frame(index: 2, sharpness: 180.0, hash: '00ff00ff00ff00ff'),
      ];

      final selected = gate.select(frames, config: const AnalysisConfig());

      expect(selected.map((f) => f.index), [0, 2]);
    });

    test('falls back to the sharpest frames when every frame is blurry', () {
      // A shaky walkthrough where nothing clears the bar should still be
      // analyzed — blurry frames beat zero frames.
      final frames = [
        _frame(index: 0, sharpness: 10.0, hash: '0000000000000000'),
        _frame(index: 1, sharpness: 30.0, hash: 'ffffffffffffffff'),
        _frame(index: 2, sharpness: 20.0, hash: '00ff00ff00ff00ff'),
      ];

      final selected = gate.select(frames, config: const AnalysisConfig());

      expect(selected, hasLength(3));
    });

    test('dedupes near-identical frames keeping the sharper copy', () {
      // Hashes differ by a single bit — the same wall filmed twice.
      final frames = [
        _frame(index: 0, sharpness: 150.0, hash: '0000000000000000'),
        _frame(index: 1, sharpness: 300.0, hash: '0000000000000001'),
        _frame(index: 2, sharpness: 200.0, hash: 'ffffffffffffffff'),
      ];

      final selected = gate.select(frames, config: const AnalysisConfig());

      expect(selected.map((f) => f.index), [1, 2]);
    });

    test('keeps frames whose hashes are genuinely different', () {
      final frames = [
        _frame(index: 0, sharpness: 150.0, hash: '0000000000000000'),
        _frame(index: 1, sharpness: 150.0, hash: 'ffffffffffffffff'),
      ];

      final selected = gate.select(frames, config: const AnalysisConfig());

      expect(selected, hasLength(2));
    });

    test('caps at topKFrames keeping the sharpest, in video order', () {
      final frames = [
        _frame(index: 0, sharpness: 500.0, hash: '0000000000000000'),
        _frame(index: 1, sharpness: 200.0, hash: 'ffffffffffffffff'),
        _frame(index: 2, sharpness: 400.0, hash: '00ff00ff00ff00ff'),
        _frame(index: 3, sharpness: 300.0, hash: 'ff00ff00ff00ff00'),
        _frame(index: 4, sharpness: 350.0, hash: '0f0f0f0f0f0f0f0f'),
      ];

      final selected = gate.select(
        frames,
        config: const AnalysisConfig(topKFrames: 3),
      );

      // Sharpest three are 0 (500), 2 (400), 4 (350) — returned
      // chronologically so review reads like the walkthrough.
      expect(selected.map((f) => f.index), [0, 2, 4]);
    });

    test('treats frames without a hash as unique', () {
      final frames = [
        _frame(index: 0, sharpness: 150.0, hash: null),
        _frame(index: 1, sharpness: 150.0, hash: null),
        _frame(index: 2, sharpness: 150.0, hash: ''),
      ];

      final selected = gate.select(frames, config: const AnalysisConfig());

      expect(selected, hasLength(3));
    });

    test('returns empty for no frames', () {
      final selected = gate.select(const [], config: const AnalysisConfig());
      expect(selected, isEmpty);
    });
  });
}

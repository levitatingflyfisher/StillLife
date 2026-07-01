import 'package:still_life/features/video_analysis/domain/entities/frame_data.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

/// Picks which extracted frames are worth an analysis call.
///
/// Three passes, all pure Dart:
/// 1. **Blur floor** — frames below [AnalysisConfig.blurThreshold]
///    (Laplacian variance) are dropped; if *no* frame clears the bar the
///    floor is waived, because analyzing a shaky walkthrough still beats
///    analyzing nothing.
/// 2. **Near-duplicate dedupe** — walking candidates sharpest-first, a
///    frame is kept only if its 64-bit perceptual hash is more than
///    [hammingThreshold] bits away from every frame already kept, so the
///    same shelf filmed for three seconds costs one call, not six.
/// 3. **Top-K cap** — at most [AnalysisConfig.topKFrames] survive (the
///    sharpest ones, since candidates are visited sharpest-first).
///
/// The result is returned in video order so downstream review reads like
/// the walkthrough, not like a sharpness ranking.
class FrameQualityGate {
  /// Maximum pHash bit distance at which two frames count as the same view.
  final int hammingThreshold;

  const FrameQualityGate({this.hammingThreshold = 5});

  List<FrameData> select(
    List<FrameData> frames, {
    required AnalysisConfig config,
  }) {
    if (frames.isEmpty) return const [];

    var candidates = frames
        .where((f) => f.sharpness >= config.blurThreshold)
        .toList();
    if (candidates.isEmpty) {
      // Blur-floor waiver: everything was shaky; analyze anyway.
      candidates = List.of(frames);
    }

    candidates.sort((a, b) => b.sharpness.compareTo(a.sharpness));

    final kept = <FrameData>[];
    for (final frame in candidates) {
      if (kept.length >= config.topKFrames) break;
      final isDuplicate = kept.any(
        (k) =>
            _hammingDistance(frame.perceptualHash, k.perceptualHash) <=
            hammingThreshold,
      );
      if (!isDuplicate) kept.add(frame);
    }

    kept.sort((a, b) => a.index.compareTo(b.index));
    return kept;
  }

  /// Bit distance between two hex-string perceptual hashes. Frames without
  /// a comparable hash are treated as maximally distant (never duplicates).
  static int _hammingDistance(String? a, String? b) {
    if (a == null || b == null || a.isEmpty || b.isEmpty) return 1 << 16;
    if (a.length != b.length) return 1 << 16;
    var distance = 0;
    for (var i = 0; i < a.length; i++) {
      final na = int.tryParse(a[i], radix: 16);
      final nb = int.tryParse(b[i], radix: 16);
      if (na == null || nb == null) return 1 << 16;
      var x = na ^ nb;
      while (x != 0) {
        distance += x & 1;
        x >>= 1;
      }
    }
    return distance;
  }
}

import 'package:still_life/features/video_analysis/domain/entities/frame_data.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

import 'frame_extraction_exception.dart';

/// Web stub of the production frame stream: errors immediately with the
/// exception type the orchestrator already treats as a failed run.
Stream<FrameData> extractVideoFrames({
  required String videoPath,
  required AnalysisConfig config,
}) => Stream.error(
  const FrameExtractionException(
    'Video frame extraction is not available on web.',
  ),
);

/// Web stub: ffmpeg does not run in the browser, so video frame extraction
/// is native-only. The stream errors immediately with the same exception
/// type callers already handle for native ffmpeg failures.
class FrameExtractor {
  FrameExtractor({required String tempDir});

  Stream<FrameData> extractFrames({
    required String videoPath,
    required AnalysisConfig config,
  }) => Stream.error(
    const FrameExtractionException(
      'Video frame extraction is not available on web.',
    ),
  );
}

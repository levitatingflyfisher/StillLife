/// Thrown when ffmpeg fails to extract frames from a video.
class FrameExtractionException implements Exception {
  final String message;
  const FrameExtractionException(this.message);

  @override
  String toString() => 'FrameExtractionException: $message';
}

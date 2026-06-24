import 'dart:typed_data';

/// A single extracted video frame with quality metrics.
class FrameData {
  final int index;
  final double timestamp;
  final Uint8List imageBytes;
  final int width;
  final int height;
  final double sharpness; // Laplacian variance — higher = sharper
  final String? perceptualHash;

  const FrameData({
    required this.index,
    required this.timestamp,
    required this.imageBytes,
    required this.width,
    required this.height,
    required this.sharpness,
    this.perceptualHash,
  });

  bool get isSharp => sharpness > 100.0;

  @override
  String toString() =>
      'FrameData(index: $index, t: ${timestamp.toStringAsFixed(1)}s, '
      'sharp: ${sharpness.toStringAsFixed(1)})';
}

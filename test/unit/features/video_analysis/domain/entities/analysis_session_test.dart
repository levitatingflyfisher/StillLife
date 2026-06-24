import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/domain/entities/analysis_session.dart';
import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

void main() {
  group('AnalysisStatus', () {
    test('has correct stage count', () {
      // 9 values: recording through complete
      expect(AnalysisStatus.values.length, 9);
    });

    test('stageIndex progresses from 0', () {
      expect(AnalysisStatus.recording.stageIndex, 0);
      expect(AnalysisStatus.extracting.stageIndex, 1);
      expect(AnalysisStatus.detecting.stageIndex, 2);
      expect(AnalysisStatus.tracking.stageIndex, 3);
      expect(AnalysisStatus.selecting.stageIndex, 4);
      expect(AnalysisStatus.classifying.stageIndex, 5);
      expect(AnalysisStatus.enhancing.stageIndex, 6);
      expect(AnalysisStatus.reviewing.stageIndex, 7);
      expect(AnalysisStatus.complete.stageIndex, 8);
    });

    test('labels are human-readable', () {
      expect(AnalysisStatus.extracting.label, 'Extracting frames');
      expect(AnalysisStatus.detecting.label, 'Detecting objects');
    });
  });

  group('AnalysisSession', () {
    final baseSession = AnalysisSession(
      id: 'session-1',
      videoPath: '/path/to/video.mp4',
      roomId: 'room-1',
      startedAt: DateTime(2025, 1, 1, 12, 0),
    );

    test('progress is 0 when no frames processed', () {
      expect(baseSession.progress, 0.0);
    });

    test('progress calculates correctly', () {
      final session = baseSession.copyWith(
        totalFrames: 100,
        processedFrames: 50,
      );
      expect(session.progress, 0.5);
    });

    test('isComplete checks status', () {
      expect(baseSession.isComplete, false);
      final done = baseSession.copyWith(status: AnalysisStatus.complete);
      expect(done.isComplete, true);
    });

    test('isProcessing is true during pipeline stages', () {
      final extracting = baseSession.copyWith(
        status: AnalysisStatus.extracting,
      );
      expect(extracting.isProcessing, true);

      final detecting = baseSession.copyWith(status: AnalysisStatus.detecting);
      expect(detecting.isProcessing, true);

      // Not processing during recording or reviewing
      expect(baseSession.isProcessing, false); // recording
      final reviewing = baseSession.copyWith(status: AnalysisStatus.reviewing);
      expect(reviewing.isProcessing, false);
    });

    test('itemCount returns number of detected objects', () {
      expect(baseSession.itemCount, 0);

      final image = Uint8List.fromList([0, 1, 2]);
      final withItems = baseSession.copyWith(
        detectedObjects: [
          DetectedObject(
            id: '1',
            label: 'tv',
            confidence: 0.9,
            boundingBox: const Rect.fromLTWH(0, 0, 10, 10),
            croppedImage: image,
            frameIndex: 0,
          ),
          DetectedObject(
            id: '2',
            label: 'couch',
            confidence: 0.85,
            boundingBox: const Rect.fromLTWH(50, 50, 20, 20),
            croppedImage: image,
            frameIndex: 1,
          ),
        ],
      );
      expect(withItems.itemCount, 2);
    });

    test('copyWith preserves original fields', () {
      final updated = baseSession.copyWith(
        status: AnalysisStatus.detecting,
        totalFrames: 60,
        processedFrames: 20,
      );

      expect(updated.id, 'session-1');
      expect(updated.videoPath, '/path/to/video.mp4');
      expect(updated.roomId, 'room-1');
      expect(updated.status, AnalysisStatus.detecting);
      expect(updated.totalFrames, 60);
      expect(updated.processedFrames, 20);
      expect(updated.startedAt, DateTime(2025, 1, 1, 12, 0));
    });

    test('default providerTier is onDevice', () {
      expect(baseSession.providerTier, AnalysisTier.onDevice);
    });
  });

  group('AnalysisConfig', () {
    test('has sensible defaults', () {
      const config = AnalysisConfig();
      expect(config.framesPerSecond, 2.0);
      expect(config.blurThreshold, 100.0);
      expect(config.confidenceThreshold, 0.4);
      expect(config.iouTrackingThreshold, 0.3);
      expect(config.maxObjectsPerSession, 200);
      expect(config.enhanceWithLlm, true);
    });

    test('can be customized', () {
      const config = AnalysisConfig(
        framesPerSecond: 4.0,
        blurThreshold: 50.0,
        confidenceThreshold: 0.6,
        iouTrackingThreshold: 0.5,
        maxObjectsPerSession: 50,
        enhanceWithLlm: false,
        preferredTier: AnalysisTier.localLlm,
      );
      expect(config.framesPerSecond, 4.0);
      expect(config.blurThreshold, 50.0);
      expect(config.confidenceThreshold, 0.6);
      expect(config.preferredTier, AnalysisTier.localLlm);
      expect(config.enhanceWithLlm, false);
    });
  });
}

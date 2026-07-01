import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/video_analysis/domain/entities/analysis_session.dart';
import 'package:still_life/features/video_analysis/domain/entities/detected_object.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

void main() {
  group('AnalysisStatus', () {
    test('covers the VLM pipeline plus honest terminal states', () {
      expect(AnalysisStatus.values, [
        AnalysisStatus.recording,
        AnalysisStatus.extracting,
        AnalysisStatus.selecting,
        AnalysisStatus.analyzing,
        AnalysisStatus.reviewing,
        AnalysisStatus.complete,
        AnalysisStatus.noAiConfigured,
        AnalysisStatus.failed,
      ]);
    });

    test('labels are human-readable', () {
      expect(AnalysisStatus.extracting.label, 'Extracting frames');
      expect(AnalysisStatus.analyzing.label, 'Identifying items');
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

    test('isProcessing is true only during pipeline stages', () {
      for (final active in [
        AnalysisStatus.extracting,
        AnalysisStatus.selecting,
        AnalysisStatus.analyzing,
      ]) {
        expect(baseSession.copyWith(status: active).isProcessing, true);
      }
      for (final settled in [
        AnalysisStatus.recording,
        AnalysisStatus.reviewing,
        AnalysisStatus.complete,
        AnalysisStatus.noAiConfigured,
        AnalysisStatus.failed,
      ]) {
        expect(baseSession.copyWith(status: settled).isProcessing, false);
      }
    });

    test('tracks how many frames survived the quality gate', () {
      expect(baseSession.selectedFrames, 0);
      final selected = baseSession.copyWith(selectedFrames: 12);
      expect(selected.selectedFrames, 12);
    });

    test('carries an honest failure message', () {
      expect(baseSession.failureMessage, isNull);
      final failed = baseSession.copyWith(
        status: AnalysisStatus.failed,
        failureMessage: 'ffmpeg exploded',
      );
      expect(failed.failureMessage, 'ffmpeg exploded');
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
            frameImage: image,
            frameIndex: 0,
          ),
          DetectedObject(
            id: '2',
            label: 'couch',
            confidence: 0.85,
            frameImage: image,
            frameIndex: 1,
          ),
        ],
      );
      expect(withItems.itemCount, 2);
    });

    test('copyWith preserves original fields', () {
      final updated = baseSession.copyWith(
        status: AnalysisStatus.analyzing,
        totalFrames: 60,
        processedFrames: 20,
      );

      expect(updated.id, 'session-1');
      expect(updated.videoPath, '/path/to/video.mp4');
      expect(updated.roomId, 'room-1');
      expect(updated.status, AnalysisStatus.analyzing);
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
      expect(config.maxObjectsPerSession, 200);
    });

    test('can be customized', () {
      const config = AnalysisConfig(
        framesPerSecond: 4.0,
        blurThreshold: 50.0,
        maxObjectsPerSession: 50,
      );
      expect(config.framesPerSecond, 4.0);
      expect(config.blurThreshold, 50.0);
      expect(config.maxObjectsPerSession, 50);
    });
  });
}

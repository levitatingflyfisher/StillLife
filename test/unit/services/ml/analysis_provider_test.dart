import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/services/ml/analysis_provider.dart';

void main() {
  group('AnalysisTier', () {
    test('has 4 tiers', () {
      expect(AnalysisTier.values, hasLength(4));
    });

    test('tiers have human-readable labels', () {
      expect(AnalysisTier.onDevice.label, 'On-Device ML');
      expect(AnalysisTier.localLlm.label, 'Local LLM (Ollama)');
      expect(AnalysisTier.cloudApi.label, 'Cloud API');
      expect(AnalysisTier.hosted.label, 'Still Life Hosted');
    });
  });

  group('AnalysisResult', () {
    test('holds all item identification data', () {
      const result = AnalysisResult(
        itemName: 'Samsung 55" OLED TV',
        brand: 'Samsung',
        model: 'QN55S90C',
        description: '55 inch OLED 4K Smart TV',
        category: 'Electronics',
        estimatedPrice: 1299.99,
        confidence: 0.95,
      );

      expect(result.itemName, 'Samsung 55" OLED TV');
      expect(result.brand, 'Samsung');
      expect(result.model, 'QN55S90C');
      expect(result.estimatedPrice, 1299.99);
      expect(result.confidence, 0.95);
    });

    test('nullable fields default correctly', () {
      const result = AnalysisResult(
        itemName: 'Unknown Object',
        description: 'An object',
        category: 'Other',
        confidence: 0.3,
      );

      expect(result.brand, isNull);
      expect(result.model, isNull);
      expect(result.estimatedPrice, isNull);
      expect(result.rawResponse, isEmpty);
    });
  });

  group('AnalysisConfig', () {
    test('has sensible defaults', () {
      const config = AnalysisConfig();
      expect(config.framesPerSecond, 2.0);
      expect(config.confidenceThreshold, 0.4);
      expect(config.enhanceWithLlm, true);
      expect(config.preferredTier, isNull);
    });

    test('can be customized', () {
      const config = AnalysisConfig(
        framesPerSecond: 5.0,
        confidenceThreshold: 0.6,
        enhanceWithLlm: false,
        preferredTier: AnalysisTier.localLlm,
      );
      expect(config.framesPerSecond, 5.0);
      expect(config.preferredTier, AnalysisTier.localLlm);
    });
  });

  group('AnalysisProgress', () {
    test('tracks processing progress', () {
      const progress = AnalysisProgress(
        currentFrame: 50,
        totalFrames: 100,
        itemsDetected: 5,
        stage: 'Object Detection',
        progress: 0.5,
      );

      expect(progress.currentFrame, 50);
      expect(progress.totalFrames, 100);
      expect(progress.itemsDetected, 5);
      expect(progress.stage, 'Object Detection');
      expect(progress.progress, 0.5);
    });
  });
}

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/features/inventory/data/services/item_photo_analysis_service.dart';
import 'package:still_life/services/ml/analysis_provider.dart';
import 'package:still_life/services/ml/provider_manager.dart';

class MockProviderManager extends Mock implements ProviderManager {}

class MockAnalysisProvider extends Mock implements AnalysisProvider {}

void main() {
  late MockProviderManager mockManager;
  late MockAnalysisProvider mockProvider;
  late ItemPhotoAnalysisService service;

  setUp(() {
    mockManager = MockProviderManager();
    mockProvider = MockAnalysisProvider();
    service = ItemPhotoAnalysisService(mockManager);
  });

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('analyzePhoto', () {
    test('returns AnalysisSuggestion when LLM succeeds', () async {
      when(
        () => mockManager.getBestAvailable(AnalysisCapability.image),
      ).thenAnswer((_) async => mockProvider);
      when(
        () => mockProvider.analyzeImage(imageBytes: any(named: 'imageBytes')),
      ).thenAnswer(
        (_) async => const AnalysisResult(
          itemName: 'Drill',
          description: 'A power drill',
          category: 'Tools',
          estimatedPrice: 89.0,
          confidence: 0.9,
        ),
      );

      final outcome = await service.analyzePhoto(Uint8List(1));

      expect(outcome, isA<AnalysisSuggestion>());
      final suggestion = (outcome as AnalysisSuggestion).suggestion;
      expect(suggestion.name, 'Drill');
      expect(suggestion.categoryName, 'Tools');
      expect(suggestion.estimatedValue, 89.0);
    });

    test('maps brand and model from the AnalysisResult', () async {
      when(
        () => mockManager.getBestAvailable(AnalysisCapability.image),
      ).thenAnswer((_) async => mockProvider);
      when(
        () => mockProvider.analyzeImage(imageBytes: any(named: 'imageBytes')),
      ).thenAnswer(
        (_) async => const AnalysisResult(
          itemName: 'Drill',
          brand: 'Bosch',
          model: 'GSB 18V-55',
          description: 'A power drill',
          category: 'Tools',
          confidence: 0.9,
        ),
      );

      final outcome = await service.analyzePhoto(Uint8List(1));

      final suggestion = (outcome as AnalysisSuggestion).suggestion;
      expect(suggestion.brand, 'Bosch');
      expect(suggestion.model, 'GSB 18V-55');
    });

    test('normalizes empty brand/model strings to null', () async {
      when(
        () => mockManager.getBestAvailable(AnalysisCapability.image),
      ).thenAnswer((_) async => mockProvider);
      when(
        () => mockProvider.analyzeImage(imageBytes: any(named: 'imageBytes')),
      ).thenAnswer(
        (_) async => const AnalysisResult(
          itemName: 'Drill',
          brand: '',
          model: '',
          description: '',
          category: 'Tools',
          confidence: 0.9,
        ),
      );

      final outcome = await service.analyzePhoto(Uint8List(1));

      final suggestion = (outcome as AnalysisSuggestion).suggestion;
      expect(suggestion.brand, isNull);
      expect(suggestion.model, isNull);
    });

    test('returns typed NoAiConfigured when no tier is available — '
        'never a stub suggestion, never an exception blob', () async {
      when(() => mockManager.getBestAvailable(AnalysisCapability.image)).thenAnswer((_) async => null);
      final outcome = await service.analyzePhoto(Uint8List(1));
      expect(outcome, isA<NoAiConfigured>());
    });

    test('returns AnalysisFailed when the LLM call throws', () async {
      when(
        () => mockManager.getBestAvailable(AnalysisCapability.image),
      ).thenAnswer((_) async => mockProvider);
      when(
        () => mockProvider.analyzeImage(imageBytes: any(named: 'imageBytes')),
      ).thenThrow(Exception('network error'));

      final outcome = await service.analyzePhoto(Uint8List(1));

      expect(outcome, isA<AnalysisFailed>());
      expect((outcome as AnalysisFailed).message, contains('network error'));
    });
  });

  group('analyzeVoice', () {
    setUp(() {
      when(
        () => mockManager.getBestAvailable(AnalysisCapability.text),
      ).thenAnswer((_) async => mockProvider);
      when(
        () => mockProvider.analyzeText(any(), context: any(named: 'context')),
      ).thenAnswer(
        (_) async => const AnalysisResult(
          itemName: 'Bosch Drill',
          description: 'power tool',
          category: 'Tools',
          estimatedPrice: 120.0,
          confidence: 0.8,
        ),
      );
    });

    test('returns AnalysisSuggestion from transcript via analyzeText', () async {
      final outcome = await service.analyzeVoice(
        'Bosch drill paid 120 dollars kitchen',
      );

      expect(outcome, isA<AnalysisSuggestion>());
      final suggestion = (outcome as AnalysisSuggestion).suggestion;
      expect(suggestion.name, 'Bosch Drill');
      expect(suggestion.categoryName, 'Tools');
      expect(suggestion.estimatedValue, 120.0);
    });

    test('sends a text prompt — never a fake image with a smuggled '
        'prompt in existingLabel', () async {
      await service.analyzeVoice('Bosch drill paid 120 dollars kitchen');

      final prompt =
          verify(
                () => mockProvider.analyzeText(
                  captureAny(),
                  context: any(named: 'context'),
                ),
              ).captured.single
              as String;
      expect(prompt, contains('Bosch drill paid 120 dollars kitchen'));
      expect(prompt.toLowerCase(), contains('json'));

      verifyNever(
        () => mockProvider.analyzeImage(
          imageBytes: any(named: 'imageBytes'),
          contextFrame: any(named: 'contextFrame'),
          existingLabel: any(named: 'existingLabel'),
        ),
      );
    });

    test('returns typed NoAiConfigured when no tier is available', () async {
      when(() => mockManager.getBestAvailable(AnalysisCapability.text)).thenAnswer((_) async => null);
      final outcome = await service.analyzeVoice('anything');
      expect(outcome, isA<NoAiConfigured>());
    });

    test('returns AnalysisFailed when the text analysis throws', () async {
      when(
        () => mockProvider.analyzeText(any(), context: any(named: 'context')),
      ).thenThrow(Exception('malformed model output'));
      final outcome = await service.analyzeVoice('anything');
      expect(outcome, isA<AnalysisFailed>());
    });
  });

  group('analyzeShelfPhoto', () {
    test('returns ShelfSuggestions with one suggestion per result, '
        'carrying brand/model/confidence', () async {
      when(
        () => mockManager.getBestAvailable(AnalysisCapability.imageMulti),
      ).thenAnswer((_) async => mockProvider);
      when(
        () => mockProvider.analyzeImageMulti(
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer(
        (_) async => const [
          AnalysisResult(
            itemName: 'Bosch Drill',
            brand: 'Bosch',
            model: 'GSB 18V-55',
            description: 'a drill',
            category: 'Tools',
            estimatedPrice: 129.99,
            confidence: 0.9,
          ),
          AnalysisResult(
            itemName: 'Paperback',
            brand: '',
            description: '',
            category: 'Books',
            confidence: 0.6,
          ),
        ],
      );

      final outcome = await service.analyzeShelfPhoto(Uint8List(1));

      expect(outcome, isA<ShelfSuggestions>());
      final suggestions = (outcome as ShelfSuggestions).suggestions;
      expect(suggestions, hasLength(2));
      expect(suggestions[0].name, 'Bosch Drill');
      expect(suggestions[0].brand, 'Bosch');
      expect(suggestions[0].model, 'GSB 18V-55');
      expect(suggestions[0].categoryName, 'Tools');
      expect(suggestions[0].estimatedValue, 129.99);
      expect(suggestions[0].confidence, 0.9);
      expect(suggestions[1].name, 'Paperback');
      expect(suggestions[1].brand, isNull,
          reason: 'empty brand strings normalize to null');
      expect(suggestions[1].confidence, 0.6);
    });

    test('returns typed NoAiConfigured when no tier is available — '
        'never an empty shelf pretending to be a result', () async {
      when(() => mockManager.getBestAvailable(AnalysisCapability.imageMulti)).thenAnswer((_) async => null);
      final outcome = await service.analyzeShelfPhoto(Uint8List(1));
      expect(outcome, isA<NoAiConfigured>());
    });

    test('returns AnalysisFailed when the multi analysis throws', () async {
      when(
        () => mockManager.getBestAvailable(AnalysisCapability.imageMulti),
      ).thenAnswer((_) async => mockProvider);
      when(
        () => mockProvider.analyzeImageMulti(
          any(),
          context: any(named: 'context'),
        ),
      ).thenThrow(Exception('vision model exploded'));

      final outcome = await service.analyzeShelfPhoto(Uint8List(1));

      expect(outcome, isA<AnalysisFailed>());
      expect((outcome as AnalysisFailed).message, contains('exploded'));
    });

    test('an empty result list stays a ShelfSuggestions — the caller '
        'decides how to degrade', () async {
      when(
        () => mockManager.getBestAvailable(AnalysisCapability.imageMulti),
      ).thenAnswer((_) async => mockProvider);
      when(
        () => mockProvider.analyzeImageMulti(
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => const []);

      final outcome = await service.analyzeShelfPhoto(Uint8List(1));

      expect(outcome, isA<ShelfSuggestions>());
      expect((outcome as ShelfSuggestions).suggestions, isEmpty);
    });
  });
}

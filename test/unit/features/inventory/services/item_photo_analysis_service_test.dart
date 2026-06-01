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

  test('analyzePhoto returns ItemSuggestion when LLM succeeds', () async {
    when(
      () => mockManager.getBestAvailable(),
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

    final result = await service.analyzePhoto(Uint8List(1));

    expect(result, isNotNull);
    expect(result!.name, 'Drill');
    expect(result.categoryName, 'Tools');
    expect(result.estimatedValue, 89.0);
  });

  test('analyzePhoto returns null when no LLM provider available', () async {
    when(() => mockManager.getBestAvailable()).thenAnswer((_) async => null);
    final result = await service.analyzePhoto(Uint8List(1));
    expect(result, isNull);
  });

  test('analyzePhoto returns null when LLM call throws', () async {
    when(
      () => mockManager.getBestAvailable(),
    ).thenAnswer((_) async => mockProvider);
    when(
      () => mockProvider.analyzeImage(imageBytes: any(named: 'imageBytes')),
    ).thenThrow(Exception('network error'));
    final result = await service.analyzePhoto(Uint8List(1));
    expect(result, isNull);
  });

  test('analyzeVoice returns suggestion from transcript', () async {
    when(
      () => mockManager.getBestAvailable(),
    ).thenAnswer((_) async => mockProvider);
    when(
      () => mockProvider.analyzeImage(
        imageBytes: any(named: 'imageBytes'),
        existingLabel: any(named: 'existingLabel'),
      ),
    ).thenAnswer(
      (_) async => const AnalysisResult(
        itemName: 'Bosch Drill',
        description: 'power tool',
        category: 'Tools',
        estimatedPrice: 120.0,
        confidence: 0.8,
      ),
    );

    final result = await service.analyzeVoice(
      'Bosch drill paid 120 dollars kitchen',
    );
    expect(result, isNotNull);
    expect(result!.name, 'Bosch Drill');
  });
}

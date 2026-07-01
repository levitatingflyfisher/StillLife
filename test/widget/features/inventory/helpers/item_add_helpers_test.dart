import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/inventory/data/services/item_photo_analysis_service.dart';
import 'package:still_life/features/inventory/domain/entities/item_suggestion.dart';
import 'package:still_life/features/inventory/presentation/helpers/item_add_helpers.dart';
import 'package:still_life/features/inventory/presentation/screens/shelf_review_screen.dart';
import 'package:still_life/services/voice/voice_input_service.dart';

class MockItemPhotoAnalysisService extends Mock
    implements ItemPhotoAnalysisService {}

/// Deterministic stand-in for speech-to-text: `listen()` completes with
/// [transcript] once `stop()` fires — mirroring the production flow
/// where dismissing the listening dialog triggers the final result.
class FakeVoiceInputService implements VoiceInputService {
  FakeVoiceInputService(this.transcript);

  final String? transcript;
  final _completer = Completer<String?>();

  @override
  Future<bool> initialize() async => true;

  @override
  bool get isListening => false;

  @override
  Future<String?> listen({void Function(String partial)? onPartial}) =>
      _completer.future;

  @override
  Future<void> stop() async {
    if (!_completer.isCompleted) _completer.complete(transcript);
  }
}

/// Camera fake: always "takes" the same tiny photo.
class FakeImagePickerPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      XFile.fromData(Uint8List.fromList([1, 2, 3]), path: '/tmp/fake.jpg');
}

void main() {
  late MockItemPhotoAnalysisService service;
  ItemSuggestion? capturedExtra;
  ShelfReviewArgs? capturedShelfArgs;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    service = MockItemPhotoAnalysisService();
    capturedExtra = null;
    capturedShelfArgs = null;
  });

  Widget buildHarness({VoiceInputService? voice}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => onPhotoAddItem(context, ref),
                    child: const Text('photo-add'),
                  ),
                  ElevatedButton(
                    onPressed: () => onVoiceAddItem(context, ref),
                    child: const Text('voice-add'),
                  ),
                ],
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: 'inventory/add',
              name: 'addItem',
              builder: (context, state) {
                capturedExtra = state.extra as ItemSuggestion?;
                return const Scaffold(body: Text('MANUAL ADD FORM'));
              },
            ),
            GoRoute(
              path: 'shelf/review',
              name: 'shelfReview',
              builder: (context, state) {
                capturedShelfArgs = state.extra as ShelfReviewArgs?;
                return const Scaffold(body: Text('SHELF REVIEW SCREEN'));
              },
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        itemPhotoAnalysisServiceProvider.overrideWithValue(service),
        if (voice != null) voiceInputServiceProvider.overrideWithValue(voice),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('onPhotoAddItem — single item', () {
    setUp(() {
      ImagePickerPlatform.instance = FakeImagePickerPlatform();
    });

    Future<void> captureAndChooseSingle(WidgetTester tester) async {
      await tester.tap(find.text('photo-add'));
      await tester.pumpAndSettle();
      expect(find.text('Single item'), findsOneWidget,
          reason: 'after capture the user chooses single vs shelf');
      expect(find.text('Many items (shelf)'), findsOneWidget);
      await tester.tap(find.text('Single item'));
      await tester.pumpAndSettle();
    }

    testWidgets('NoAiConfigured shows the honest snackbar and opens the '
        'manual form with just the photo — no fake suggestion', (tester) async {
      when(
        () => service.analyzePhoto(any()),
      ).thenAnswer((_) async => const NoAiConfigured());

      await tester.pumpWidget(buildHarness());
      await captureAndChooseSingle(tester);

      expect(
        find.textContaining('No AI provider configured'),
        findsOneWidget,
      );
      expect(find.textContaining('Settings'), findsOneWidget);
      expect(find.text('MANUAL ADD FORM'), findsOneWidget);
      expect(capturedExtra, isNotNull);
      expect(capturedExtra!.photoPath, '/tmp/fake.jpg');
      expect(capturedExtra!.photoBytes, Uint8List.fromList([1, 2, 3]),
          reason: 'the captured bytes must ride into the add form so the '
              'photo can attach on save (paths are unusable on web)');
      expect(capturedExtra!.name, isNull);
      expect(capturedExtra!.estimatedValue, isNull);
    });

    testWidgets('a real suggestion navigates without any no-AI snackbar',
        (tester) async {
      when(() => service.analyzePhoto(any())).thenAnswer(
        (_) async =>
            const AnalysisSuggestion(ItemSuggestion(name: 'Bosch Drill')),
      );

      await tester.pumpWidget(buildHarness());
      await captureAndChooseSingle(tester);

      expect(find.textContaining('No AI provider configured'), findsNothing);
      expect(find.text('MANUAL ADD FORM'), findsOneWidget);
      expect(capturedExtra!.name, 'Bosch Drill');
      expect(capturedExtra!.photoPath, '/tmp/fake.jpg');
      expect(capturedExtra!.photoBytes, Uint8List.fromList([1, 2, 3]));
    });

    testWidgets('dismissing the mode sheet abandons the flow quietly',
        (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.tap(find.text('photo-add'));
      await tester.pumpAndSettle();

      // Tap outside the sheet to dismiss it.
      await tester.tapAt(const Offset(400, 40));
      await tester.pumpAndSettle();

      expect(find.text('MANUAL ADD FORM'), findsNothing);
      expect(find.text('SHELF REVIEW SCREEN'), findsNothing);
      verifyNever(() => service.analyzePhoto(any()));
      verifyNever(() => service.analyzeShelfPhoto(any()));
    });
  });

  group('onPhotoAddItem — many items (shelf)', () {
    setUp(() {
      ImagePickerPlatform.instance = FakeImagePickerPlatform();
    });

    Future<void> captureAndChooseShelf(WidgetTester tester) async {
      await tester.tap(find.text('photo-add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Many items (shelf)'));
      await tester.pumpAndSettle();
    }

    testWidgets('suggestions open the shelf review screen carrying the '
        'suggestions and the full photo bytes', (tester) async {
      when(() => service.analyzeShelfPhoto(any())).thenAnswer(
        (_) async => const ShelfSuggestions([
          ItemSuggestion(name: 'Bosch Drill', confidence: 0.9),
          ItemSuggestion(name: 'Old Paperback', confidence: 0.6),
        ]),
      );

      await tester.pumpWidget(buildHarness());
      await captureAndChooseShelf(tester);

      expect(find.text('SHELF REVIEW SCREEN'), findsOneWidget);
      expect(find.textContaining('No AI provider configured'), findsNothing);
      expect(capturedShelfArgs, isNotNull);
      expect(capturedShelfArgs!.suggestions, hasLength(2));
      expect(capturedShelfArgs!.suggestions.first.name, 'Bosch Drill');
      expect(capturedShelfArgs!.photoBytes, Uint8List.fromList([1, 2, 3]),
          reason: 'the review screen attaches this exact frame to each item');
    });

    testWidgets('NoAiConfigured shows the same settings-pointing snackbar '
        'and does NOT open the review screen', (tester) async {
      when(
        () => service.analyzeShelfPhoto(any()),
      ).thenAnswer((_) async => const NoAiConfigured());

      await tester.pumpWidget(buildHarness());
      await captureAndChooseShelf(tester);

      expect(
        find.textContaining('No AI provider configured'),
        findsOneWidget,
      );
      expect(find.text('SHELF REVIEW SCREEN'), findsNothing);
      expect(find.text('MANUAL ADD FORM'), findsOneWidget,
          reason: 'the photo is kept — the manual form still gets it');
      expect(capturedExtra!.photoBytes, Uint8List.fromList([1, 2, 3]));
      expect(capturedExtra!.name, isNull);
    });

    testWidgets('an empty shelf result says so and falls through to the '
        'manual form with the photo', (tester) async {
      when(
        () => service.analyzeShelfPhoto(any()),
      ).thenAnswer((_) async => const ShelfSuggestions([]));

      await tester.pumpWidget(buildHarness());
      await captureAndChooseShelf(tester);

      expect(find.textContaining('No items identified'), findsOneWidget);
      expect(find.text('SHELF REVIEW SCREEN'), findsNothing);
      expect(find.text('MANUAL ADD FORM'), findsOneWidget);
      expect(capturedExtra!.photoBytes, Uint8List.fromList([1, 2, 3]));
    });

    testWidgets('AnalysisFailed lands on the manual form with the photo — '
        'data is never dropped', (tester) async {
      when(
        () => service.analyzeShelfPhoto(any()),
      ).thenAnswer((_) async => const AnalysisFailed('boom'));

      await tester.pumpWidget(buildHarness());
      await captureAndChooseShelf(tester);

      expect(find.text('SHELF REVIEW SCREEN'), findsNothing);
      expect(find.text('MANUAL ADD FORM'), findsOneWidget);
      expect(capturedExtra!.photoBytes, Uint8List.fromList([1, 2, 3]));
      expect(find.textContaining('No AI provider configured'), findsNothing);
    });

    testWidgets('AnalysisFailed SAYS the analysis failed — a broken key '
        'must be distinguishable from nothing-found', (tester) async {
      when(
        () => service.analyzeShelfPhoto(any()),
      ).thenAnswer((_) async => const AnalysisFailed('401 revoked key'));

      await tester.pumpWidget(buildHarness());
      await captureAndChooseShelf(tester);

      expect(find.textContaining('AI analysis failed'), findsOneWidget,
          reason: 'the failure branch was the ONLY silent one; the typed '
              'outcome exists so the UI can tell the user their AI setup '
              'broke');
      expect(find.textContaining('401 revoked key'), findsOneWidget,
          reason: 'AnalysisFailed.message must actually be shown');
      expect(find.text('MANUAL ADD FORM'), findsOneWidget);
    });
  });

  group('onVoiceAddItem', () {
    testWidgets('NoAiConfigured shows the honest snackbar and opens the '
        'manual form with the transcript preserved as notes', (tester) async {
      when(
        () => service.analyzeVoice(any()),
      ).thenAnswer((_) async => const NoAiConfigured());
      final voice = FakeVoiceInputService('bosch drill from the garage');

      await tester.pumpWidget(buildHarness(voice: voice));
      await tester.tap(find.text('voice-add'));
      await tester.pump();
      expect(find.text('Listening...'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No AI provider configured'),
        findsOneWidget,
      );
      expect(find.text('MANUAL ADD FORM'), findsOneWidget);
      expect(capturedExtra, isNotNull);
      expect(capturedExtra!.notes, 'bosch drill from the garage');
      expect(capturedExtra!.name, isNull);
    });

    testWidgets('AnalysisFailed still lands on the manual form with the '
        'transcript in notes — data is never dropped', (tester) async {
      when(
        () => service.analyzeVoice(any()),
      ).thenAnswer((_) async => const AnalysisFailed('boom'));
      final voice = FakeVoiceInputService('teak bookshelf');

      await tester.pumpWidget(buildHarness(voice: voice));
      await tester.tap(find.text('voice-add'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('MANUAL ADD FORM'), findsOneWidget);
      expect(capturedExtra!.notes, 'teak bookshelf');
      expect(find.textContaining('No AI provider configured'), findsNothing);
      expect(find.textContaining('AI analysis failed'), findsOneWidget,
          reason: 'voice flow surfaces the failure too');
    });

    testWidgets('a real suggestion is passed through untouched',
        (tester) async {
      when(() => service.analyzeVoice(any())).thenAnswer(
        (_) async => const AnalysisSuggestion(
          ItemSuggestion(name: 'Bosch Drill', estimatedValue: 120),
        ),
      );
      final voice = FakeVoiceInputService('bosch drill 120 dollars');

      await tester.pumpWidget(buildHarness(voice: voice));
      await tester.tap(find.text('voice-add'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('MANUAL ADD FORM'), findsOneWidget);
      expect(capturedExtra!.name, 'Bosch Drill');
      expect(capturedExtra!.estimatedValue, 120);
      expect(find.textContaining('No AI provider configured'), findsNothing);
    });
  });
}

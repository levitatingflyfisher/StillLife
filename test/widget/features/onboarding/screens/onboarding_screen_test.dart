import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/providers/profile_providers.dart';
import 'package:still_life/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:still_life/features/profiles/domain/entities/profile.dart';

import '../../../../mocks/fake_profile_repository.dart';

/// In-memory stub for [ActiveProfileNotifier] — avoids FlutterSecureStorage
/// plugin calls in the widget-test environment.
class _FakeActiveProfileNotifier extends ActiveProfileNotifier {
  @override
  Future<Profile?> build() async => null;

  @override
  Future<void> setActive(Profile? p) async {
    state = AsyncData(p);
  }
}

Widget buildSubject() => ProviderScope(
  overrides: [
    profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
    activeProfileProvider.overrideWith(() => _FakeActiveProfileNotifier()),
  ],
  child: const MaterialApp(home: OnboardingScreen()),
);

void main() {
  group('OnboardingScreen', () {
    testWidgets('shows welcome page on first load', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Still Life'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('navigates to profile setup page on Get Started tap', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text("Who's setting this up?"), findsOneWidget);
      expect(find.text("That's me \u2192"), findsOneWidget);
      expect(find.text('Skip \u2192'), findsOneWidget);
    });

    testWidgets('skip on profile page navigates to features page', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip \u2192'));
      await tester.pumpAndSettle();

      expect(find.text('Everything in one place'), findsOneWidget);
      expect(find.text("Let's Go"), findsOneWidget);
    });

    testWidgets('features page lists key capabilities', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip \u2192'));
      await tester.pumpAndSettle();

      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Financial dashboard'), findsOneWidget);
      expect(find.text('LAN sync'), findsOneWidget);
    });

    testWidgets('shows privacy notice on features page', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip \u2192'));
      await tester.pumpAndSettle();

      expect(find.textContaining('no account'), findsOneWidget);
    });

    testWidgets('profile setup page shows emoji and color swatches', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // The default emoji is shown as large display
      expect(find.text('\u{1F464}'), findsWidgets);
      // Name field with hint text
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is TextField && (w.decoration?.hintText ?? '') == 'Your name',
        ),
        findsOneWidget,
      );
      // 8 color swatches
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets(
      "That's me button creates profile and advances to features page",
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pump();

        // Step 1: navigate to profile setup page
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        // Step 2: enter a name
        await tester.enterText(
          find.byWidgetPredicate(
            (w) =>
                w is TextField && (w.decoration?.hintText ?? '') == 'Your name',
          ),
          'Test User',
        );

        // Step 3: tap "That's me →"
        await tester.tap(find.text("That's me \u2192"));

        // Step 4: pump to settle without pumpAndSettle (avoids animation timeout)
        // — first pump lets async futures (createProfile + setActive) resolve,
        // — second pump advances the 300 ms page-flip animation to completion.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Step 5: Features page is now visible
        expect(find.text('Everything in one place'), findsOneWidget);
      },
    );
  });
}

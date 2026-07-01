import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/failures.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/profile_providers.dart';
import 'package:still_life/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:still_life/features/profiles/domain/entities/profile.dart';
import 'package:still_life/features/profiles/domain/repositories/profile_repository.dart';

/// A repository whose writes always fail — reproduces the on-device report
/// where the SQLite database never opened (its first-open error is cached by
/// drift's LazyDatabase), so every write throws and first-run onboarding
/// dead-ends on the profile page with only a generic, undismissable message.
class _FailingProfileRepository implements ProfileRepository {
  const _FailingProfileRepository(this.message);
  final String message;

  Err<T> _err<T>() => Err<T>(DatabaseFailure(message));

  @override
  Future<Result<Profile>> createProfile(Profile profile) async => _err();
  @override
  Stream<List<Profile>> watchProfiles() => Stream<List<Profile>>.value(const []);
  @override
  Future<Result<Profile>> getProfile(String id) async => _err();
  @override
  Future<Result<Profile>> updateProfile(Profile profile) async => _err();
  @override
  Future<Result<void>> deleteProfile(String id) async => _err();
  @override
  Future<Result<void>> setDefault(String id) async => _err();
}

Widget _subject(String failMessage) => ProviderScope(
      overrides: [
        profileRepositoryProvider
            .overrideWithValue(_FailingProfileRepository(failMessage)),
      ],
      child: const MaterialApp(home: OnboardingScreen()),
    );

Future<void> _enterNameAndSubmit(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byWidgetPredicate(
      (w) => w is TextField && (w.decoration?.hintText ?? '') == 'Your name',
    ),
    'Dana',
  );
  await tester.tap(find.text("That's me →"));
  await tester.pump(); // resolve the createProfile future
  await tester.pumpAndSettle(); // surface the failure dialog
}

void main() {
  setUp(() {
    // A tall surface so the profile page never overflows in the test env.
    // (physicalSize is reset automatically between tests.)
  });

  testWidgets(
    'surfaces the real save error so a stuck user can report what failed',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _subject('SqliteException(1): no such table: profiles'),
      );
      await _enterNameAndSubmit(tester);

      // The actual failure text must reach the user — not a generic
      // "Could not save profile" that hides which subsystem broke.
      expect(find.textContaining('no such table: profiles'), findsOneWidget);
    },
  );

  testWidgets(
    'offers an in-context way forward when the profile cannot be saved',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_subject('disk I/O error'));
      await _enterNameAndSubmit(tester);

      // A tappable escape from the dead-end, presented with the error...
      final skip = find.text('Continue without a profile');
      expect(skip, findsOneWidget);

      // ...and it advances past the profile page to the features page.
      await tester.tap(skip);
      await tester.pumpAndSettle();
      expect(find.text('Everything in one place'), findsOneWidget);
    },
  );
}

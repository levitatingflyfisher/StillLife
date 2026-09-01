import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/loans/presentation/controllers/loan_controller.dart';
import 'package:still_life/features/loans/presentation/screens/all_loans_screen.dart';
import 'package:still_life/core/widgets/failure_feedback.dart';

/// A failed load says what didn't happen in plain words, offers Try again,
/// and keeps the exception behind Details — never as the message.
void main() {
  const raw = 'SqliteException(11): database disk image is malformed';

  testWidgets('a screen whose data failed to load shows no raw exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeLoansProvider.overrideWith(
            (ref) => Stream.error(Exception(raw)),
          ),
        ],
        child: const MaterialApp(home: AllLoansScreen()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('SqliteException'), findsNothing);
    expect(find.text("Couldn’t load loans"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  test('failureSentence never carries the exception text', () {
    final s = failureSentence("Couldn't export", Exception(raw));
    expect(s, startsWith("Couldn't export."));
    expect(s, isNot(contains('Sqlite')));
  });
}

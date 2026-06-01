import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/reports/domain/entities/policy.dart';
import 'package:still_life/features/reports/presentation/controllers/policy_controller.dart';
import 'package:still_life/features/reports/presentation/screens/policy_screen.dart';

void main() {
  final now = DateTime(2025, 6, 1);

  Widget buildSubject({List<Policy> policies = const []}) {
    return ProviderScope(
      overrides: [policiesProvider.overrideWith((_) => Stream.value(policies))],
      child: const MaterialApp(home: PolicyScreen()),
    );
  }

  group('PolicyScreen', () {
    testWidgets('shows empty state when no policies', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('No policies yet'), findsOneWidget);
      expect(
        find.text('Add your insurance policy to track coverage gaps'),
        findsOneWidget,
      );
    });

    testWidgets('shows FAB in empty state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows list of policies when non-empty', (tester) async {
      final policies = [
        Policy(
          id: 'pol1',
          propertyId: 'prop1',
          provider: 'State Farm',
          policyNumber: 'SF-001',
          coverageAmount: 200000,
          createdAt: now,
        ),
        Policy(
          id: 'pol2',
          propertyId: 'prop1',
          provider: 'Allstate',
          createdAt: now,
        ),
      ];
      await tester.pumpWidget(buildSubject(policies: policies));
      await tester.pumpAndSettle();

      expect(find.text('State Farm'), findsOneWidget);
      expect(find.text('Allstate'), findsOneWidget);
      expect(find.text('No policies yet'), findsNothing);
    });

    testWidgets('shows expired badge for expired policy', (tester) async {
      final expired = Policy(
        id: 'pol1',
        propertyId: 'prop1',
        provider: 'Old Insurer',
        expiryDate: DateTime(2020, 1, 1),
        createdAt: now,
      );
      await tester.pumpWidget(buildSubject(policies: [expired]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Expired'), findsOneWidget);
    });

    testWidgets('shows coverage amount when set', (tester) async {
      final policy = Policy(
        id: 'pol1',
        propertyId: 'prop1',
        provider: 'State Farm',
        coverageAmount: 150000,
        createdAt: now,
      );
      await tester.pumpWidget(buildSubject(policies: [policy]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Coverage'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policiesProvider.overrideWith(
              (_) => const Stream<List<Policy>>.empty(),
            ),
          ],
          child: const MaterialApp(home: PolicyScreen()),
        ),
      );
      // Stream has not emitted; expect loading state.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

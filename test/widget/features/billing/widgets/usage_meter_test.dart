import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/billing/domain/account.dart';
import 'package:still_life/features/billing/presentation/widgets/usage_meter.dart';

void main() {
  testWidgets('shows percent, tokens, reset date', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UsageMeter(
            account: Account(
              tier: 'pro',
              status: SubscriptionStatus.active,
              tokensUsedMonth: 25000,
              tokensMonthCap: 50000,
              // Add 5 days + 1 hour so `.inDays` rounds down to exactly 5
              // even after the widget runs (`inDays` truncates).
              monthResetAt: DateTime.now().add(
                const Duration(days: 5, hours: 1),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('25000 / 50000 tokens'), findsOneWidget);
    expect(find.textContaining('in 5 days'), findsOneWidget);
  });

  testWidgets('renders "soon" when reset date is in the past', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UsageMeter(
            account: Account(
              tier: 'pro',
              status: SubscriptionStatus.active,
              tokensUsedMonth: 0,
              tokensMonthCap: 1000,
              monthResetAt: DateTime.now().subtract(const Duration(hours: 1)),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('soon'), findsOneWidget);
  });

  testWidgets('clamps progress bar at 100% when over cap', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UsageMeter(
            account: Account(
              tier: 'pro',
              status: SubscriptionStatus.active,
              tokensUsedMonth: 999999,
              tokensMonthCap: 1000,
              monthResetAt: DateTime.now().add(const Duration(days: 1)),
            ),
          ),
        ),
      ),
    );
    final progress = t.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 1.0);
  });
}

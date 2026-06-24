import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/billing_providers.dart';
import 'package:still_life/features/billing/domain/account.dart';
import 'package:still_life/features/billing/domain/billing_service.dart';
import 'package:still_life/features/billing/presentation/screens/pro_status_screen.dart';
import 'package:still_life/features/billing/presentation/widgets/upgrade_cta.dart';
import 'package:still_life/features/billing/presentation/widgets/usage_meter.dart';

class _FakeBilling extends Mock implements BillingService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://x'));
  });

  testWidgets('shows UpgradeCta when account is null', (t) async {
    final b = _FakeBilling();
    when(
      () => b.buildCheckoutUrl(),
    ).thenReturn(Uri.parse('https://checkout.test'));

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          billingServiceProvider.overrideWithValue(b),
          accountProvider.overrideWith(_NullAccountNotifier.new),
        ],
        child: const MaterialApp(home: ProStatusScreen()),
      ),
    );
    await t.pumpAndSettle();

    expect(find.byType(UpgradeCta), findsOneWidget);
    expect(find.byType(UsageMeter), findsNothing);
  });

  testWidgets('shows UsageMeter and status chip when account is active', (
    t,
  ) async {
    final b = _FakeBilling();
    when(
      () => b.buildCheckoutUrl(),
    ).thenReturn(Uri.parse('https://checkout.test'));

    final acc = Account(
      tier: 'pro',
      status: SubscriptionStatus.active,
      tokensUsedMonth: 1000,
      tokensMonthCap: 50000,
      monthResetAt: DateTime.now().add(const Duration(days: 10)),
    );

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          billingServiceProvider.overrideWithValue(b),
          accountProvider.overrideWith(() => _StubAccountNotifier(acc)),
        ],
        child: const MaterialApp(home: ProStatusScreen()),
      ),
    );
    await t.pumpAndSettle();

    expect(find.byType(UsageMeter), findsOneWidget);
    expect(find.text('Pro — active'), findsOneWidget);
    expect(find.text('Rotate bearer'), findsOneWidget);
    expect(find.text('Delete Pro account'), findsOneWidget);
  });

  testWidgets('Rotate bearer tap calls service and shows snackbar', (t) async {
    final b = _FakeBilling();
    when(
      () => b.buildCheckoutUrl(),
    ).thenReturn(Uri.parse('https://checkout.test'));
    when(() => b.rotateBearer()).thenAnswer((_) async => const Success(null));

    final acc = Account(
      tier: 'pro',
      status: SubscriptionStatus.active,
      tokensUsedMonth: 1000,
      tokensMonthCap: 50000,
      monthResetAt: DateTime.now().add(const Duration(days: 10)),
    );

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          billingServiceProvider.overrideWithValue(b),
          accountProvider.overrideWith(() => _StubAccountNotifier(acc)),
        ],
        child: const MaterialApp(home: ProStatusScreen()),
      ),
    );
    await t.pumpAndSettle();

    await t.tap(find.text('Rotate bearer'));
    await t.pump();
    await t.pump();

    verify(() => b.rotateBearer()).called(1);
    expect(find.text('New bearer issued'), findsOneWidget);
  });
}

class _NullAccountNotifier extends AccountNotifier {
  @override
  Future<Account?> build() async => null;
}

class _StubAccountNotifier extends AccountNotifier {
  _StubAccountNotifier(this._acc);
  final Account _acc;
  @override
  Future<Account?> build() async => _acc;
}

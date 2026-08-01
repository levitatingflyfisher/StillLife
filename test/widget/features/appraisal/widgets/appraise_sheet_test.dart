import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/appraisal_providers.dart';
import 'package:still_life/features/appraisal/domain/entities/appraisal.dart';
import 'package:still_life/features/appraisal/domain/entities/appraisal_source.dart';
import 'package:still_life/features/appraisal/domain/repositories/appraisal_repository.dart';
import 'package:still_life/features/appraisal/presentation/widgets/appraise_sheet.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';

class _StubRepo implements AppraisalRepository {
  final Map<AppraisalMode, Appraisal?> store;
  final List<Appraisal> applied = [];
  _StubRepo(this.store);

  @override
  Future<Result<void>> delete(String id) async => const Success(null);
  @override
  Future<Result<void>> applyToItem(Appraisal a) async {
    applied.add(a);
    return const Success(null);
  }

  @override
  Future<Appraisal?> getLatestByCacheKey(
    String itemModelKey,
    AppraisalMode mode,
    String countryCode,
  ) async => store[mode];
  @override
  Future<Appraisal?> getLatestByItemAndMode(
    String itemId,
    AppraisalMode mode,
  ) async => store[mode];
  @override
  Future<Result<Appraisal>> save(Appraisal a) async => Success(a);
  @override
  Stream<List<Appraisal>> watchForItem(String itemId) =>
      Stream.value(store.values.whereType<Appraisal>().toList());
}

Item sampleItem() => Item(
  id: 'i1',
  name: 'Samsung TV',
  description: '',
  categoryId: 'c',
  roomId: 'r',
  createdAt: DateTime(2024),
  modifiedAt: DateTime(2024),
);

Appraisal mkAppraisal(AppraisalMode mode, int value) {
  final now = DateTime.now();
  return Appraisal(
    id: 'a-${mode.wire}',
    itemId: 'i1',
    mode: mode,
    valueCents: value,
    currency: 'USD',
    confidence: 0.8,
    sources: const [
      AppraisalSource(url: 'https://x.com', title: 'X', price: 100),
    ],
    itemModelKey: 'samsung tv|unknown',
    countryCode: 'US',
    queriedAt: now,
    expiresAt: now.add(const Duration(days: 30)),
  );
}

Widget harness(AppraisalRepository repo, AppraisalMode mode) => ProviderScope(
  overrides: [appraisalRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    home: Scaffold(
      body: AppraiseSheet(item: sampleItem(), mode: mode),
    ),
  ),
);

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('no Apply button before an estimate exists', (tester) async {
    await tester.pumpWidget(harness(_StubRepo({}), AppraisalMode.resale));
    await settle(tester);
    expect(find.text('Apply to item'), findsNothing);
  });

  testWidgets('Apply to item hands the appraisal to the repository', (
    tester,
  ) async {
    final repo = _StubRepo({
      AppraisalMode.resale: mkAppraisal(AppraisalMode.resale, 450),
    });
    await tester.pumpWidget(harness(repo, AppraisalMode.resale));
    await settle(tester);

    expect(find.text('Apply to item'), findsOneWidget);
    await tester.tap(find.text('Apply to item'));
    await settle(tester);

    expect(repo.applied, hasLength(1));
    expect(repo.applied.single.id, 'a-resale');
  });

  testWidgets('after applying, the button confirms inline and goes inert', (
    tester,
  ) async {
    final repo = _StubRepo({
      AppraisalMode.resale: mkAppraisal(AppraisalMode.resale, 450),
    });
    await tester.pumpWidget(harness(repo, AppraisalMode.resale));
    await settle(tester);

    await tester.tap(find.text('Apply to item'));
    await settle(tester);

    expect(find.text('Applied'), findsOneWidget);
    expect(find.text('Apply to item'), findsNothing);

    // A second tap must not double-write.
    await tester.tap(find.text('Applied'));
    await settle(tester);
    expect(repo.applied, hasLength(1));
  });

  testWidgets('resale copy says the target is current value', (tester) async {
    final repo = _StubRepo({
      AppraisalMode.resale: mkAppraisal(AppraisalMode.resale, 450),
    });
    await tester.pumpWidget(harness(repo, AppraisalMode.resale));
    await settle(tester);
    expect(find.textContaining('current value'), findsOneWidget);
  });

  testWidgets('replace mode copy says the target is replacement cost', (
    tester,
  ) async {
    final repo = _StubRepo({
      AppraisalMode.replaceNew: mkAppraisal(AppraisalMode.replaceNew, 799),
    });
    await tester.pumpWidget(harness(repo, AppraisalMode.replaceNew));
    await settle(tester);
    expect(find.textContaining('replacement cost'), findsOneWidget);
  });

  testWidgets('a zero-confidence estimate offers no Apply button', (
    tester,
  ) async {
    final zero = mkAppraisal(AppraisalMode.resale, 0).copyWith(
      valueCents: () => 0,
      confidence: () => 0,
    );
    final repo = _StubRepo({AppraisalMode.resale: zero});
    await tester.pumpWidget(harness(repo, AppraisalMode.resale));
    await settle(tester);
    expect(find.text('Apply to item'), findsNothing);
  });
}

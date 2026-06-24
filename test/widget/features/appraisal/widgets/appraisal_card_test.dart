import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/core/errors/result.dart';
import 'package:still_life/core/providers/appraisal_providers.dart';
import 'package:still_life/features/appraisal/domain/entities/appraisal.dart';
import 'package:still_life/features/appraisal/domain/entities/appraisal_source.dart';
import 'package:still_life/features/appraisal/domain/repositories/appraisal_repository.dart';
import 'package:still_life/features/appraisal/presentation/widgets/appraisal_card.dart';
import 'package:still_life/features/inventory/domain/entities/item.dart';

class _StubRepo implements AppraisalRepository {
  final Map<AppraisalMode, Appraisal?> store;
  _StubRepo(this.store);

  @override
  Future<Result<void>> delete(String id) async => const Success(null);
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

Appraisal mkAppraisal(AppraisalMode mode, double value) {
  final now = DateTime.now();
  return Appraisal(
    id: 'a-${mode.wire}',
    itemId: 'i1',
    mode: mode,
    value: value,
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

Widget harness(AppraisalRepository repo) => ProviderScope(
  overrides: [appraisalRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    home: Scaffold(body: AppraisalCard(item: sampleItem())),
  ),
);

void main() {
  testWidgets('AppraisalCard renders chips for all three modes', (
    tester,
  ) async {
    await tester.pumpWidget(harness(_StubRepo(const {})));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Resale'), findsOneWidget);
    expect(find.textContaining('Replace New'), findsOneWidget);
    expect(find.textContaining('Replace Equivalent'), findsOneWidget);
  });

  testWidgets('AppraisalCard shows cached value when present', (tester) async {
    await tester.pumpWidget(
      harness(
        _StubRepo({
          AppraisalMode.resale: mkAppraisal(AppraisalMode.resale, 450),
        }),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('\$450'), findsOneWidget);
  });

  testWidgets('Tapping a chip opens the AppraiseSheet', (tester) async {
    await tester.pumpWidget(harness(_StubRepo(const {})));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.textContaining('Resale'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Resale estimate'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/features/recently_deleted/data/recently_deleted_repository.dart';
import 'package:still_life/features/recently_deleted/presentation/recently_deleted_screen.dart';
import 'package:still_life/features/recently_deleted/presentation/undo_providers.dart';

class _MockTrash extends Mock implements RecentlyDeletedRepository {}

void main() {
  late _MockTrash trash;
  late StreamController<List<DeletedItem>> deleted;

  setUp(() {
    trash = _MockTrash();
    deleted = StreamController<List<DeletedItem>>();
    when(() => trash.watchDeletedItems()).thenAnswer((_) => deleted.stream);
    when(() => trash.restoreItem(any())).thenAnswer((_) async {});
  });
  tearDown(() => deleted.close());

  Widget subject() => ProviderScope(
    overrides: [recentlyDeletedRepositoryProvider.overrideWithValue(trash)],
    child: const MaterialApp(home: RecentlyDeletedScreen()),
  );

  testWidgets('lists deleted items and restores one', (tester) async {
    await tester.pumpWidget(subject());
    deleted.add([
      DeletedItem(id: 'i2', name: 'Lamp', deletedAt: DateTime(2025, 3, 1)),
      DeletedItem(id: 'i1', name: 'TV', deletedAt: DateTime(2025, 2, 1)),
    ]);
    await tester.pump();

    expect(find.text('Lamp'), findsOneWidget);
    expect(find.text('TV'), findsOneWidget);
    // Honest: nothing here claims it cannot be undone, and nothing is
    // purged on a timer.
    expect(find.textContaining('cannot be undone'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Restore').first);
    await tester.pump();
    verify(() => trash.restoreItem('i2')).called(1);
    expect(find.textContaining('Restored “Lamp”'), findsOneWidget);
  });

  testWidgets('says plainly when nothing is deleted', (tester) async {
    await tester.pumpWidget(subject());
    deleted.add(const []);
    await tester.pump();
    expect(find.text('Nothing deleted'), findsOneWidget);
  });
}

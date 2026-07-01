import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';
import 'package:still_life/features/backup/presentation/photo_snapshots_section.dart';

void main() {
  late InMemoryVaultStore store;
  late BackupVault vault;

  setUp(() {
    store = InMemoryVaultStore();
    vault = BackupVault(store, appId: 'stilllife', keepN: 2, extension: 'ohbkz');
  });

  Future<void> pump(
    WidgetTester tester, {
    Future<void> Function(String id)? onRestore,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhotoSnapshotsSection(
              vault: vault,
              onRestoreSnapshot: onRestore ?? (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty vault shows the calm explainer, not a blank', (tester) async {
    await pump(tester);
    expect(find.text('Previous photo backups'), findsOneWidget);
    expect(find.textContaining('saved automatically'), findsOneWidget);
  });

  testWidgets('lists snapshots with label + age, newest first', (tester) async {
    await vault.save(Uint8List.fromList([1, 2, 3]),
        label: VaultLabel.preRestore);
    await pump(tester);

    expect(find.text('Safety snapshot'), findsOneWidget);
    expect(find.textContaining('made today'), findsOneWidget);
  });

  testWidgets('restore asks first, promises the counter-snapshot, then routes '
      'through the guarded flow', (tester) async {
    final entry = await vault.save(Uint8List.fromList([1, 2, 3]),
        label: VaultLabel.preRestore);
    String? restoredId;
    await pump(tester, onRestore: (id) async => restoredId = id);

    await tester.tap(find.byTooltip('Restore this snapshot'));
    await tester.pumpAndSettle();
    expect(find.textContaining('saved first'), findsOneWidget,
        reason: 'restoring a snapshot is itself guarded — say so');

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(restoredId, entry.id);
  });

  testWidgets('restore confirm copy is merge-honest: no "rolls back" promise',
      (tester) async {
    await vault.save(Uint8List.fromList([1, 2, 3]),
        label: VaultLabel.preRestore);
    await pump(tester);

    await tester.tap(find.byTooltip('Restore this snapshot'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rolls'), findsNothing,
        reason: 'the import is an upsert-merge — items added since the '
            'snapshot survive, so "rolls back" over-promises');
    expect(find.textContaining('merges'), findsOneWidget,
        reason: 'say what actually happens: a merge that overwrites '
            'records/photos sharing an id');
    expect(find.textContaining('saved first'), findsOneWidget,
        reason: 'the counter-snapshot promise stays');
  });

  testWidgets('delete asks first, then removes the snapshot', (tester) async {
    final entry = await vault.save(Uint8List.fromList([1, 2, 3]),
        label: VaultLabel.manual);
    await pump(tester);

    await tester.tap(find.byTooltip('Delete snapshot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(await store.read(entry.id), isNull);
    expect(find.textContaining('saved automatically'), findsOneWidget,
        reason: 'list refreshes back to the empty explainer');
  });
}

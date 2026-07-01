import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:still_life/features/backup/backup_wiring.dart';

void main() {
  group('sanctuaryBackupOverrides config', () {
    late ProviderContainer container;
    late SanctuaryBackupConfig config;

    setUp(() {
      container = ProviderContainer(overrides: sanctuaryBackupOverrides());
      addTearDown(container.dispose);
      config = container.read(sanctuaryBackupConfigProvider);
    });

    test('identity: appId/aadContext are the shipped values', () {
      expect(config.appId, 'stilllife');
      expect(config.aadContext, 'stilllife-backup/v1');
    });

    // StillLife's restore is an upsert-MERGE (importFromJson lww:false), not a
    // destructive replace. The package defaults its confirm dialog to
    // 'Replace all data?' / 'Replace everything' — which would be a lie over a
    // merge. backup_config.dart's own doc says merge apps MUST override both.
    test('confirm dialog copy is merge-honest, not the replace defaults', () {
      expect(config.confirmTitle, 'Merge backup into this device?');
      expect(config.confirmActionLabel, 'Merge backup');
    });

    test('consequence copy describes the merge, echoing the honest wording',
        () {
      expect(config.restoreReplaceConsequence, contains('merges'));
      expect(config.restoreReplaceConsequence, isNot(contains('delete all')));
    });
  });
}

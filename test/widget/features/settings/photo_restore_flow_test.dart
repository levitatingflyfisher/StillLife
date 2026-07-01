import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';
import 'package:still_life/core/providers/database_provider.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/backup/backup_wiring.dart';
import 'package:still_life/features/backup/photo_backup_providers.dart';
import 'package:still_life/features/backup/presentation/photo_backup_tile.dart';
import 'package:still_life/features/backup/presentation/photo_restore_flow.dart';
import 'package:still_life/services/backup/photo_backup_container.dart';
import 'package:still_life/services/backup/still_life_backup_serializer.dart';
import 'package:still_life/services/database/database.dart';
import 'package:still_life/services/export/import_service.dart';
import 'package:still_life/services/export/json_export_service.dart';

import '../../../test_setup.dart';

/// The key FakeCryptoService derives for any phrase (fill = 7).
final _deviceKey = Uint8List(32)..fillRange(0, 32, 7);

const _phrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon about';

/// A second phrase [_PhraseKeyedCryptoService] maps to a DIFFERENT key
/// (fill = 9) — models a backup made on another household's device.
const _foreignPhrase =
    'legal winner thank year wave sausage worth useful legal winner thank '
    'yellow';

final _foreignKey = Uint8List(32)..fillRange(0, 32, 9);

/// Unlike the base fake (any phrase → fill 7), derives per-phrase keys so
/// wrong-phrase scenarios are honest: [_phrase] → 7, anything else → 9.
class _PhraseKeyedCryptoService extends FakeCryptoService {
  @override
  Future<DerivedKeys> deriveKeysFromPhrase(
    String phrase, {
    String? appDomain,
  }) async {
    final fill = phrase == _phrase ? 7 : 9;
    Uint8List filled(int v) => Uint8List(32)..fillRange(0, 32, v);
    return DerivedKeys(
      masterEncryptionKey: filled(fill),
      syncKey: filled(fill + 1),
      authKey: filled(fill + 2),
      recoveryKey: filled(fill + 3),
      syncChannelId: filled(fill + 4),
    );
  }
}

Future<void> _seed(AppDatabase db, {required String suffix}) async {
  final now = DateTime(2026);
  await db.into(db.properties).insert(PropertiesCompanion.insert(
      id: 'p_$suffix', name: 'Home', createdAt: now, modifiedAt: now));
  await db.into(db.rooms).insert(RoomsCompanion.insert(
      id: 'r_$suffix',
      propertyId: 'p_$suffix',
      name: 'Room',
      createdAt: now,
      modifiedAt: now));
  await db.into(db.categories).insert(CategoriesCompanion.insert(
      id: 'c_$suffix', name: 'Cat', createdAt: now, modifiedAt: now));
  await db.into(db.items).insert(ItemsCompanion.insert(
      id: 'item_$suffix',
      name: 'Item $suffix',
      categoryId: 'c_$suffix',
      roomId: 'r_$suffix',
      createdAt: now,
      modifiedAt: now));
  await db.into(db.photos).insert(PhotosCompanion.insert(
      id: 'photo_$suffix',
      itemId: 'item_$suffix',
      filePath: '',
      bytes: Value(Uint8List.fromList(const [1, 2, 3])),
      capturedAt: now,
      createdAt: now,
      modifiedAt: now));
}

BackupRepository _repoFor(AppDatabase db) => BackupRepository(
      StillLifeBackupSerializer(
        exportService: JsonExportService(db),
        importService: ImportService(db, photoRootResolver: () async => null),
      ),
      EnvelopeCipher(),
      aadContext: 'stilllife-backup/v1',
    );

/// A photos-included `.ohbkz` sealed under [key] (the fake device key by
/// default).
Future<Uint8List> _incomingContainer({Uint8List? key}) async {
  final src = AppDatabase.memory();
  addTearDown(src.close);
  await _seed(src, suffix: 'new');
  final container = PhotoBackupContainer(
    db: src,
    metadataRepo: _repoFor(src),
  );
  return (await container.exportContainer(key ?? _deviceKey)).bytes;
}

/// A container whose metadata opens fine under the device key but whose
/// photo entry does NOT (validly sealed under a different key): a damaged/
/// tampered backup, emphatically not a wrong-words one.
Future<Uint8List> _containerWithBadPhotoEntry() async {
  final bytes = await _incomingContainer();
  final archive = ZipDecoder().decodeBytes(bytes);
  final out = Archive();
  for (final f in archive.files) {
    if (f.name == 'photos/photo_new.ohbk') {
      final sealed = await GhostBackup.export(
        Uint8List.fromList(const [6, 6, 6]),
        _foreignKey,
        EnvelopeCipher(),
        context: 'stilllife-photo/v1|photo|photo_new',
      );
      out.addFile(ArchiveFile.bytes(f.name, sealed));
    } else {
      out.addFile(ArchiveFile.bytes(f.name, Uint8List.fromList(f.content)));
    }
  }
  return ZipEncoder().encodeBytes(out);
}

void main() {
  ensureSqlite3();

  late AppDatabase db;
  late InMemoryVaultStore photoStore;
  late InMemoryVaultStore metadataStore;

  setUp(() async {
    db = AppDatabase.memory();
    photoStore = InMemoryVaultStore();
    metadataStore = InMemoryVaultStore();
    await _seed(db, suffix: 'old');
  });

  tearDown(() => db.close());

  Future<void> pumpFlowHost(
    WidgetTester tester,
    Uint8List bytes, {
    SecureKeyStore? keyStore,
    CryptoService? crypto,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          secureKeyStoreProvider.overrideWithValue(
            keyStore ??
                InMemorySecureKeyStore(mnemonic: _phrase, acknowledged: true),
          ),
          cryptoServiceProvider.overrideWithValue(crypto ?? FakeCryptoService()),
          vaultStoreProvider.overrideWithValue(metadataStore),
          photoVaultStoreProvider.overrideWithValue(photoStore),
          // path_provider's platform channel never answers inside a widget
          // test's FakeAsync zone — importFromJson would hang forever on
          // _resolvePhotoRoot. Use the service's test seam instead.
          importServiceProvider.overrideWith(
            (ref) => ImportService(ref.watch(databaseProvider),
                photoRootResolver: () async => null),
          ),
          ...sanctuaryBackupOverrides(),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () =>
                    const PhotoRestoreFlow().restorePicked(context, ref, bytes),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('confirm dialog makes the rollback promise, not a threat',
      (tester) async {
    await pumpFlowHost(tester, await _incomingContainer());
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.textContaining('roll back'), findsOneWidget,
        reason: 'with a mandatory snapshot the copy must promise the rollback');
    expect(find.textContaining('cannot be undone'), findsNothing,
        reason: 'with a pre-restore snapshot "cannot be undone" is a lie');
    expect(find.textContaining('photos included'), findsOneWidget,
        reason: 'the photo path must say its snapshot covers photos');

    // Cancel: nothing restored, nothing vaulted.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final items = await db.select(db.items).get();
    expect(items.map((i) => i.id), isNot(contains('item_new')));
    expect(await photoStore.list(), isEmpty);
  });

  testWidgets(
      'bare .ohbk confirm copy promises a records-only snapshot — not the '
      'photos-included one it cannot deliver', (tester) async {
    final src = AppDatabase.memory();
    addTearDown(src.close);
    await _seed(src, suffix: 'new');
    final bareOhbk = await _repoFor(src).export(_deviceKey);

    await pumpFlowHost(tester, bareOhbk);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.textContaining('photos included'), findsNothing,
        reason: 'a bare .ohbk gets a records-only snapshot — promising a '
            'photos-included one is a lie');
    expect(find.textContaining('without photos'), findsOneWidget,
        reason: 'the copy must say honestly what the snapshot covers');
    expect(find.textContaining('roll back'), findsOneWidget,
        reason: 'the rollback promise itself stays — it is true');
  });

  testWidgets(
      'confirmed .ohbkz restore takes the photo-vault snapshot then applies',
      (tester) async {
    await pumpFlowHost(tester, await _incomingContainer());
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.text('Backup restored.'), findsOneWidget);
    final items = await db.select(db.items).get();
    expect(items.map((i) => i.id), contains('item_new'));

    final entries = await photoStore.list();
    expect(entries, hasLength(1),
        reason: 'the guarded flow must vault a pre-restore snapshot');
    expect(entries.single.label, VaultLabel.preRestore);
    expect(entries.single.id, endsWith('.ohbkz'));
  });

  testWidgets(
      'fresh install: a successful phrase restore ADOPTS the phrase as the '
      'device identity (restore-adopt)', (tester) async {
    final freshStore = InMemorySecureKeyStore(); // no mnemonic: fresh install
    await pumpFlowHost(tester, await _incomingContainer(),
        keyStore: freshStore);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    // No device key → the flow asks for the recovery words.
    expect(find.text('Enter your recovery words'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, _phrase);
    await tester.tap(find.text('Restore').last);
    await tester.pumpAndSettle();

    expect(find.text('Backup restored.'), findsOneWidget);
    final items = await db.select(db.items).get();
    expect(items.map((i) => i.id), contains('item_new'));

    // The restore-adopt promise: typing the words to restore IS proof of
    // possession, so the phrase becomes this device's identity — otherwise
    // the device stays keyless and the pre-restore snapshot it just made
    // can never be opened again.
    expect(await freshStore.readMnemonic(), _phrase,
        reason: 'the typed phrase must be adopted as the device mnemonic');
    expect(await freshStore.readSeedAcknowledged(), isTrue,
        reason: 'typing the words to restore is proof of possession');
  });

  testWidgets(
      'foreign-phrase restore seals the safety snapshot under the DEVICE key '
      '(the rollback must open with this device\'s credentials)',
      (tester) async {
    // Device identity: _phrase → fill 7. Backup: another device's phrase →
    // fill 9. The device key can't open the backup, so the flow falls back
    // to the backup's words — but the SNAPSHOT it takes is of THIS device's
    // data and must stay openable by THIS device's identity.
    await pumpFlowHost(
      tester,
      await _incomingContainer(key: _foreignKey),
      crypto: _PhraseKeyedCryptoService(),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.textContaining('different set of words'), findsOneWidget,
        reason: 'the device key must fail first, prompting for the '
            "backup's words");
    await tester.enterText(find.byType(TextField).last, _foreignPhrase);
    await tester.tap(find.text('Restore').last);
    await tester.pumpAndSettle();

    expect(find.text('Backup restored.'), findsOneWidget);

    // THE INVARIANT: the pre-restore snapshot is always openable by the
    // post-restore device identity. This device kept its own identity
    // (adoption never overwrites an existing mnemonic), so the snapshot
    // must open under the DEVICE key — sealed under the incoming key it
    // would be rollback theater.
    final entries = await photoStore.list();
    expect(entries, hasLength(1));
    final snapshotBytes = await photoStore.read(entries.single.id);
    final rollbackDb = AppDatabase.memory();
    addTearDown(rollbackDb.close);
    final rollback = PhotoBackupContainer(
      db: rollbackDb,
      metadataRepo: _repoFor(rollbackDb),
    );
    await rollback.importContainer(snapshotBytes!, _deviceKey);
    final rolled = await rollbackDb.select(rollbackDb.items).get();
    expect(rolled.map((i) => i.id), contains('item_old'),
        reason: 'the snapshot must roll back under the device credentials');
  });

  testWidgets(
      'a corrupt photo entry gets honest "damaged" copy, NOT the '
      'wrong-words prompt', (tester) async {
    // The metadata opens under the device key — the key is right. A photo
    // entry that then fails to decrypt means the FILE is damaged; blaming
    // the words sends the user hunting for a phrase that cannot exist.
    await pumpFlowHost(tester, await _containerWithBadPhotoEntry());

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.textContaining('different set of words'), findsNothing,
        reason: 'the key already opened the metadata — "different words" '
            'is a lie here');
    expect(find.textContaining('damaged'), findsOneWidget,
        reason: 'the honest diagnosis is a damaged backup file');

    // The single-transaction import rolled back: nothing half-restored.
    final items = await db.select(db.items).get();
    expect(items.map((i) => i.id), isNot(contains('item_new')));
    expect(items.map((i) => i.id), contains('item_old'));
  });

  testWidgets(
      'vault-snapshot restore shows ONE dialog: the section confirm is not '
      'followed by a second, contradicting flow confirm', (tester) async {
    // Seed the photo vault with a valid snapshot sealed under the device
    // key, then drive the real tile wiring end to end.
    final vault = BackupVault(photoStore,
        appId: 'stilllife', keepN: 2, extension: 'ohbkz');
    await vault.save(await _incomingContainer(), label: VaultLabel.preRestore);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          secureKeyStoreProvider.overrideWithValue(
            InMemorySecureKeyStore(mnemonic: _phrase, acknowledged: true),
          ),
          cryptoServiceProvider.overrideWithValue(FakeCryptoService()),
          vaultStoreProvider.overrideWithValue(metadataStore),
          photoVaultStoreProvider.overrideWithValue(photoStore),
          importServiceProvider.overrideWith(
            (ref) => ImportService(ref.watch(databaseProvider),
                photoRootResolver: () async => null),
          ),
          ...sanctuaryBackupOverrides(),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: PhotoBackupTile())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Restore this snapshot'));
    await tester.pumpAndSettle();
    expect(find.text('Restore this snapshot?'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.text('Restore this backup?'), findsNothing,
        reason: 'one action gets one honest dialog — a second stacked '
            'confirm with contradicting copy is a dark pattern');
    expect(find.text('Backup restored.'), findsOneWidget,
        reason: 'the confirmed restore must proceed straight through');
    final items = await db.select(db.items).get();
    expect(items.map((i) => i.id), contains('item_new'));
  });

  testWidgets('snapshot failure aborts with an honest dialog and no restore',
      (tester) async {
    await pumpFlowHost(tester, await _incomingContainer());
    photoStore.failNextPut = true;

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.textContaining('safety snapshot'), findsOneWidget,
        reason: 'a refused restore must say WHY (fail-closed, honestly)');
    expect(find.textContaining('was not started'), findsOneWidget,
        reason: 'the user must know their data was not touched');

    final items = await db.select(db.items).get();
    expect(items.map((i) => i.id), isNot(contains('item_new')),
        reason: 'fail-closed: no restore without a verified snapshot');
    expect(items.map((i) => i.id), contains('item_old'));
  });
}

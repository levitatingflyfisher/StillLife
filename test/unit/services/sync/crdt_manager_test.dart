import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/sync/crdt_manager.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockStorage storage;
  late CrdtManager manager;

  setUp(() {
    storage = _MockStorage();
    manager = CrdtManager(storage);
  });

  group('CrdtManager.getNodeId', () {
    test('generates and stores a UUID on first call', () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final id = await manager.getNodeId();

      expect(id, isNotEmpty);
      // UUID v4: 36 chars with hyphens
      expect(id.length, 36);
      verify(() => storage.write(key: 'sync_node_id', value: id)).called(1);
    });

    test('returns cached nodeId on subsequent calls', () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final id1 = await manager.getNodeId();
      final id2 = await manager.getNodeId();

      expect(id1, id2);
      // storage.write called only once (second call returns cached)
      verify(
        () => storage.write(
          key: 'sync_node_id',
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('restores nodeId from storage', () async {
      const storedId = 'test-node-uuid-1234';
      // Register general stub first; specific stub last so it takes priority.
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => storage.read(key: 'sync_node_id'),
      ).thenAnswer((_) async => storedId);

      final id = await manager.getNodeId();
      expect(id, storedId);
    });
  });

  group('CrdtManager.nextHlc', () {
    test('returns monotonically increasing HLC strings', () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final hlc1 = await manager.nextHlc();
      final hlc2 = await manager.nextHlc();

      expect(hlc1.toString(), isNotEmpty);
      expect(hlc2.toString(), isNotEmpty);
      // HLC must be monotonically non-decreasing
      expect(hlc2.compareTo(hlc1), greaterThan(0));
    });

    test('persists HLC to storage', () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await manager.nextHlc();

      verify(
        () => storage.write(
          key: 'sync_hlc',
          value: any(named: 'value'),
        ),
      ).called(greaterThan(0));
    });
  });

  group('CrdtManager.mergeHlc', () {
    test('returns current HLC when remote string is empty', () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await manager.nextHlc(); // initialise
      final result = manager.mergeHlc('');
      expect(result.toString(), isNotEmpty);
    });

    test('handles invalid remote HLC gracefully', () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await manager.nextHlc();
      expect(() => manager.mergeHlc('not-a-valid-hlc'), returnsNormally);
    });
  });

  group('CrdtManager.setSyncSecret', () {
    test('rejects secrets shorter than 16 characters', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await expectLater(
        manager.setSyncSecret('too-short'),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        manager.setSyncSecret(''),
        throwsA(isA<ArgumentError>()),
      );
      // 15-char boundary
      await expectLater(
        manager.setSyncSecret('a' * 15),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(
        () => storage.write(
          key: 'sync_secret',
          value: any(named: 'value'),
        ),
      );
    });

    test('accepts secrets of exactly 16 characters', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final ok = 'a' * 16;
      await manager.setSyncSecret(ok);
      verify(() => storage.write(key: 'sync_secret', value: ok)).called(1);
    });

    test('accepts longer secrets and persists them', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      const secret = 'correct-horse-battery-staple-a-very-long-secret';
      await manager.setSyncSecret(secret);
      verify(() => storage.write(key: 'sync_secret', value: secret)).called(1);
    });
  });

  // ── concurrency ───────────────────────────────────────────────────────────
  //
  // Every stamp this class hands out is a position in a total order. Two rows
  // that share a position are two rows a last-writer-wins merge cannot choose
  // between, so the winner comes down to iteration order on whichever device
  // happens to run the merge — the one thing sync must never depend on.
  //
  // The tests above all call one method at a time, which is the one shape
  // that cannot expose this. Real callers do not: `sync_providers.dart` hands
  // the same instance to the server, the discovery service and the client,
  // and a sync writes many rows without awaiting between them.
  group('CrdtManager under concurrent callers', () {
    test('never hands out the same HLC twice', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      // What a burst of row writes looks like: many stamps requested before
      // any of them has finished persisting.
      final stamps = await Future.wait([
        for (var i = 0; i < 20; i++) manager.nextHlc(),
      ]);

      final rendered = stamps.map((h) => h.toString()).toList();
      expect(rendered.toSet().length, rendered.length,
          reason: 'duplicate stamps make the merge order arbitrary: '
              '${rendered.length - rendered.toSet().length} collision(s)');
    });

    test('concurrent stamps are strictly increasing', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final stamps = await Future.wait([
        for (var i = 0; i < 20; i++) manager.nextHlc(),
      ]);

      // Lexicographic order on the rendered form IS the merge's comparison,
      // so that is what has to be monotonic — not just the parsed value.
      final rendered = stamps.map((h) => h.toString()).toList();
      final sorted = [...rendered]..sort();
      expect(rendered, sorted,
          reason: 'stamps were issued out of order, so a later write can '
              'lose to an earlier one');
    });

    test('concurrent first calls agree on one node identity', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final ids = await Future.wait([
        for (var i = 0; i < 8; i++) manager.getNodeId(),
      ]);

      // A device that answers with two different identities has, as far as
      // every peer is concerned, become two devices.
      expect(ids.toSet().length, 1,
          reason: 'minted ${ids.toSet().length} identities: ${ids.toSet()}');
    });

    test('one identity even when the storage read is slow', () async {
      // The previous test passes by scheduling luck: the mock resolves so
      // promptly that the first caller finishes before the others resume.
      // A real keystore read does not. Delay it and the interleaving the
      // code actually permits becomes visible.
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return null;
      });
      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final ids = await Future.wait([
        for (var i = 0; i < 8; i++) manager.getNodeId(),
      ]);

      expect(ids.toSet().length, 1,
          reason: 'minted ${ids.toSet().length} identities — to every peer '
              'this device just became ${ids.toSet().length} devices');
    });

    test('pairing with a new secret replaces the one already read', () async {
      // Reading memoizes; setting must invalidate that memo. Otherwise you
      // paste the code from the other device, the app reports success, and
      // every later read still hands back the OLD secret — so pairing
      // silently does nothing.
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'original-secret-value');
      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      expect(await manager.getSyncSecret(), 'original-secret-value');
      await manager.setSyncSecret('a-brand-new-shared-secret');

      expect(await manager.getSyncSecret(), 'a-brand-new-shared-secret');
    });

    test('a corrupt stored clock is survivable, not fatal', () async {
      // The node id reads fine; the clock does not. Today Hlc.parse throws
      // straight out of nextHlc() and the caller's write dies with it.
      when(() => storage.read(key: 'sync_node_id'))
          .thenAnswer((_) async => 'node-abc');
      when(() => storage.read(key: 'sync_hlc'))
          .thenAnswer((_) async => 'not-an-hlc');
      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await expectLater(manager.nextHlc(), completes);
    });
  });
}

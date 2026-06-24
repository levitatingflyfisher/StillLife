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
}

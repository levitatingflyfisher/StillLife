import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/services/sync/crdt_manager.dart';
import 'package:still_life/services/network/lan_discovery.dart';

class _MockCrdtManager extends Mock implements CrdtManager {}

void main() {
  late _MockCrdtManager crdtManager;
  late LanDiscovery discovery;

  setUp(() {
    crdtManager = _MockCrdtManager();
    discovery = LanDiscovery(crdtManager: crdtManager);
  });

  tearDown(() async {
    await discovery.dispose();
  });

  group('LanDiscovery', () {
    test(
      'discoverPeers completes without error when mDNS unavailable',
      () async {
        when(
          () => crdtManager.getNodeId(),
        ).thenAnswer((_) async => 'local-node-id');

        // mDNS will fail in test environment — should yield 0 peers, not throw.
        final peers = await discovery
            .discoverPeers(timeout: const Duration(milliseconds: 100))
            .toList();

        expect(peers, isEmpty);
      },
    );

    test('dispose can be called multiple times safely', () async {
      when(
        () => crdtManager.getNodeId(),
      ).thenAnswer((_) async => 'local-node-id');

      await discovery.dispose();
      await discovery.dispose(); // second call must not throw
    });
  });
}

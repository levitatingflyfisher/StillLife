import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:still_life/core/providers/sync_providers.dart';
import 'package:still_life/features/sync/domain/entities/sync_peer.dart';
import 'package:still_life/features/sync/presentation/controllers/sync_controller.dart';
import 'package:still_life/features/sync/presentation/screens/sync_screen.dart';
import 'package:still_life/services/network/lan_discovery.dart';
import 'package:still_life/services/sync/lan_sync_server.dart';

class _MockLanSyncServer extends Mock implements LanSyncServer {}

class _MockLanDiscovery extends Mock implements LanDiscovery {}

class _FakeSyncController extends SyncController {
  final SyncState _initial;

  _FakeSyncController(this._initial);

  @override
  Future<SyncState> build() async => _initial;

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> syncWithPeer(SyncPeer peer) async {}

  @override
  Future<void> addManualPeer(String host, int port) async {}
}

Widget buildSubject(SyncState initialState) {
  final fakeServer = _MockLanSyncServer();
  when(() => fakeServer.start()).thenAnswer((_) async {});
  when(() => fakeServer.stop()).thenAnswer((_) async {});

  final fakeDiscovery = _MockLanDiscovery();
  when(() => fakeDiscovery.startAdvertising()).thenAnswer((_) async {});
  when(() => fakeDiscovery.stopAdvertising()).thenAnswer((_) async {});
  when(() => fakeDiscovery.dispose()).thenAnswer((_) async {});

  return ProviderScope(
    overrides: [
      syncControllerProvider.overrideWith(
        () => _FakeSyncController(initialState),
      ),
      syncSecretProvider.overrideWith((ref) async => 'test-sync-code'),
      lanSyncServerProvider.overrideWithValue(fakeServer),
      lanDiscoveryProvider.overrideWithValue(fakeDiscovery),
    ],
    child: const MaterialApp(home: SyncScreen()),
  );
}

void main() {
  group('SyncScreen', () {
    testWidgets('shows empty state when no peers found', (tester) async {
      await tester.pumpWidget(buildSubject(const SyncState()));
      await tester.pumpAndSettle();

      expect(find.text('No devices found on this network'), findsOneWidget);
    });

    testWidgets('shows peer list when peers are available', (tester) async {
      const peers = [
        SyncPeer(
          nodeId: 'node-1',
          host: '192.168.1.10',
          port: 8420,
          deviceName: 'Kitchen Tablet',
        ),
        SyncPeer(
          nodeId: 'node-2',
          host: '192.168.1.11',
          port: 8420,
          deviceName: 'Bedroom Phone',
        ),
      ];

      await tester.pumpWidget(buildSubject(const SyncState(peers: peers)));
      await tester.pumpAndSettle();

      expect(find.text('Kitchen Tablet'), findsOneWidget);
      expect(find.text('Bedroom Phone'), findsOneWidget);
      expect(find.text('Sync Now'), findsNWidgets(2));
    });

    testWidgets('shows syncing indicator when isSyncing is true', (
      tester,
    ) async {
      const peers = [
        SyncPeer(
          nodeId: 'node-1',
          host: '192.168.1.10',
          port: 8420,
          deviceName: 'Kitchen Tablet',
        ),
      ];

      await tester.pumpWidget(
        buildSubject(const SyncState(peers: peers, isSyncing: true)),
      );
      // pumpAndSettle would time out because CircularProgressIndicator animates
      // indefinitely; pump() twice is enough to let the AsyncNotifier resolve.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // When syncing, the CircularProgressIndicator replaces the "Sync Now" button.
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Sync Now'), findsNothing);
    });

    testWidgets('shows Add Device FAB', (tester) async {
      await tester.pumpWidget(buildSubject(const SyncState()));
      await tester.pumpAndSettle();

      expect(find.text('Add Device'), findsOneWidget);
    });

    testWidgets('shows manual IP dialog when FAB tapped', (tester) async {
      await tester.pumpWidget(buildSubject(const SyncState()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Device'));
      await tester.pumpAndSettle();

      expect(find.text('Add Device Manually'), findsOneWidget);
      expect(find.text('IP Address'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('displays last-synced badge for synced peer', (tester) async {
      final peers = [
        SyncPeer(
          nodeId: 'node-1',
          host: '192.168.1.10',
          port: 8420,
          deviceName: 'Kitchen Tablet',
          lastSyncAt: DateTime(2025, 6, 1, 14, 30),
        ),
      ];

      await tester.pumpWidget(buildSubject(SyncState(peers: peers)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Last synced'), findsOneWidget);
    });
  });
}

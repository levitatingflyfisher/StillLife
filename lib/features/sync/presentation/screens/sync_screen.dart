import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/providers/sync_providers.dart';
import '../../../../../services/network/lan_discovery.dart';
import '../../../../../services/sync/lan_sync_server.dart';
import '../controllers/sync_controller.dart';
import '../../domain/entities/sync_peer.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  // Hold references so dispose() can stop them without touching `ref`.
  LanSyncServer? _server;
  LanDiscovery? _discovery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Start server + mDNS advertising when the sync screen opens.
      final server = ref.read(lanSyncServerProvider);
      final discovery = ref.read(lanDiscoveryProvider);
      _server = server;
      _discovery = discovery;
      await server.start().catchError((_) {});
      if (!mounted) return;
      await discovery.startAdvertising().catchError((_) {});
      if (!mounted) return;
      ref.read(syncControllerProvider.notifier).startDiscovery();
    });
  }

  @override
  void dispose() {
    // Stop server + advertising using the locally cached references.
    _server?.stop().catchError((_) {});
    _discovery?.stopAdvertising().catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(syncControllerProvider);
    final secretAsync = ref.watch(syncSecretProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync & Backup'),
        actions: [
          if (asyncState.isLoading)
            const Padding(
              padding: OhSpacing.insetMd,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Sync code card — always visible at the top.
          _SyncCodeCard(secretAsync: secretAsync),
          Expanded(
            child: asyncState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (syncState) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(syncControllerProvider.notifier).startDiscovery(),
                child: _buildBody(context, syncState),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showManualIpDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SyncState state) {
    if (state.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.lastError!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      });
    }

    if (state.peers.isEmpty) {
      return _buildEmptyState(context, state.isSyncing);
    }

    return ListView.builder(
      padding: OhSpacing.insetMd,
      itemCount: state.peers.length,
      itemBuilder: (context, index) =>
          _PeerCard(peer: state.peers[index], isSyncing: state.isSyncing),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSyncing) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices_other_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: OhSpacing.md),
            Text(
              'No devices found on this network',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OhSpacing.sm),
            Text(
              'Make sure other devices are on the same Wi-Fi and have the Sync screen open.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OhSpacing.lg),
            if (isSyncing)
              const CircularProgressIndicator()
            else
              FilledButton.icon(
                onPressed: () =>
                    ref.read(syncControllerProvider.notifier).startDiscovery(),
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualIpDialog(BuildContext context) async {
    final ipController = TextEditingController();
    final portController = TextEditingController(text: '8420');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Device Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.x',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              decoration: const InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final host = ipController.text.trim();
      final port = int.tryParse(portController.text.trim()) ?? 8420;
      if (host.isNotEmpty) {
        await ref
            .read(syncControllerProvider.notifier)
            .addManualPeer(host, port);
      }
    }
  }
}

/// Shows this device's sync code and lets the user set a new one (to match
/// a code copied from another device).
class _SyncCodeCard extends ConsumerWidget {
  final AsyncValue<String> secretAsync;

  const _SyncCodeCard({required this.secretAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: OhSpacing.insetMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Sync Code', style: theme.textTheme.titleSmall),
            const SizedBox(height: OhSpacing.xs),
            Text(
              'All devices sharing inventory must use the same sync code.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            secretAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Could not load sync code'),
              data: (secret) => Row(
                children: [
                  Expanded(
                    child: Text(
                      secret,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: secret));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sync code copied')),
                      );
                    },
                  ),
                  TextButton(
                    child: const Text('Change'),
                    onPressed: () => _showSetCodeDialog(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetCodeDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final newCode = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          String? errorText;
          return AlertDialog(
            title: const Text('Set Sync Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paste the sync code from another device to pair them.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Sync code',
                    helperText: 'Must be at least 16 characters.',
                    errorText: errorText,
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final v = controller.text.trim();
                  if (v.isEmpty) {
                    setState(() => errorText = 'Sync code cannot be empty.');
                    return;
                  }
                  if (v.length < 16) {
                    setState(
                      () => errorText =
                          'Sync code must be at least 16 characters.',
                    );
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sync code must be at least 16 characters.',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx, v);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (newCode != null) {
      try {
        await ref.read(crdtManagerProvider).setSyncSecret(newCode);
        // Invalidate the cached secret so the UI refreshes.
        ref.invalidate(syncSecretProvider);
      } on ArgumentError catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message?.toString() ?? 'Invalid sync code'),
            ),
          );
        }
      }
    }
  }
}

class _PeerCard extends ConsumerWidget {
  final SyncPeer peer;
  final bool isSyncing;

  const _PeerCard({required this.peer, required this.isSyncing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSyncLabel = peer.lastSyncAt != null
        ? 'Last synced ${DateFormat.jm().format(peer.lastSyncAt!)}'
        : 'Not yet synced';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.phone_android_outlined),
        title: Text(peer.deviceName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${peer.host}:${peer.port}'),
            Text(lastSyncLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        isThreeLine: true,
        trailing: isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FilledButton.tonal(
                onPressed: () => ref
                    .read(syncControllerProvider.notifier)
                    .syncWithPeer(peer),
                child: const Text('Sync Now'),
              ),
      ),
    );
  }
}

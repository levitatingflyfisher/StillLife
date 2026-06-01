import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../inventory/domain/entities/item.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  /// When [returnMode] is true, scanning pops with the barcode string instead
  /// of showing the BarcodeResultSheet. Used by ItemEditScreen.
  final bool returnMode;

  const BarcodeScannerScreen({super.key, this.returnMode = false});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  Barcode? _detectedBarcode;
  Item? _foundItem;
  bool _isPaused = false;

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isPaused) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() {
      _detectedBarcode = barcode;
      _isPaused = true;
    });
    _controller.stop();

    if (widget.returnMode) {
      // In returnMode, pop immediately with the raw barcode string.
      if (mounted) context.pop(barcode.rawValue);
    } else {
      _lookupAndShowSheet(barcode);
    }
  }

  Future<void> _lookupAndShowSheet(Barcode barcode) async {
    // Check local inventory (pure local DB, no network).
    final existing = await ref
        .read(itemRepositoryProvider)
        .findByBarcode(barcode.rawValue!);
    if (!mounted) return;
    setState(() => _foundItem = existing);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Barcode detected: ${barcode.rawValue}'),
        duration: const Duration(seconds: 2),
      ),
    );
    _showResultSheet();
  }

  void _showResultSheet() {
    final barcode = _detectedBarcode;
    if (barcode == null) return;

    final found = _foundItem;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => BarcodeResultSheet(
        barcode: barcode,
        existingItem: found,
        onScanAgain: () {
          Navigator.of(ctx).pop();
          _resumeScanning();
        },
        onAddToInventory: found == null
            ? () {
                Navigator.of(ctx).pop();
                context.pushNamed(
                  'addItem',
                  queryParameters: {
                    if (barcode.rawValue != null) 'barcode': barcode.rawValue!,
                  },
                );
              }
            : null,
        onViewItem: found != null
            ? () {
                Navigator.of(ctx).pop();
                context.pushNamed(
                  'itemDetail',
                  pathParameters: {'itemId': found.id},
                );
              }
            : null,
        onEditItem: found != null
            ? () {
                Navigator.of(ctx).pop();
                context.pushNamed(
                  'editItem',
                  pathParameters: {'itemId': found.id},
                );
              }
            : null,
        onMoveItem: found != null
            ? () {
                Navigator.of(ctx).pop();
                // Navigate to edit screen so user can change room/container.
                // A dedicated move sheet is planned for a later phase.
                context.pushNamed(
                  'editItem',
                  pathParameters: {'itemId': found.id},
                );
              }
            : null,
        onLogMaintenance: found != null
            ? () {
                Navigator.of(ctx).pop();
                context.pushNamed(
                  'addMaintenance',
                  queryParameters: {'itemId': found.id},
                );
              }
            : null,
      ),
    ).then((_) {
      if (_isPaused && mounted) _resumeScanning();
    });
  }

  void _resumeScanning() {
    setState(() {
      _detectedBarcode = null;
      _foundItem = null;
      _isPaused = false;
    });
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onBarcodeDetected,
      ),
    );
  }
}

class BarcodeResultSheet extends StatelessWidget {
  final Barcode barcode;
  final Item? existingItem;
  final VoidCallback onScanAgain;
  final VoidCallback? onAddToInventory;
  final VoidCallback? onViewItem;
  final VoidCallback? onEditItem;
  final VoidCallback? onMoveItem;
  final VoidCallback? onLogMaintenance;

  const BarcodeResultSheet({
    super.key,
    required this.barcode,
    required this.onScanAgain,
    this.existingItem,
    this.onAddToInventory,
    this.onViewItem,
    this.onEditItem,
    this.onMoveItem,
    this.onLogMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: OhSpacing.md),
          Text('Barcode Detected', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: OhSpacing.insetMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OhSpacing.xs),
                  Text(barcode.format.name, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Value',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OhSpacing.xs),
                  SelectableText(
                    barcode.rawValue ?? 'Unknown',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (existingItem != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'In Inventory',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: OhSpacing.xs),
                    Text(
                      existingItem!.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: OhSpacing.md),
          if (existingItem != null) ...[
            FilledButton.icon(
              onPressed: onViewItem,
              icon: const Icon(Icons.open_in_new),
              label: const Text('View Item'),
            ),
            const SizedBox(height: OhSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: onEditItem,
                ),
                _ActionButton(
                  icon: Icons.drive_file_move_outlined,
                  label: 'Move',
                  onTap: onMoveItem,
                ),
                _ActionButton(
                  icon: Icons.build_outlined,
                  label: 'Maintenance',
                  onTap: onLogMaintenance,
                ),
              ],
            ),
          ] else
            FilledButton.icon(
              onPressed: onAddToInventory,
              icon: const Icon(Icons.add),
              label: const Text('Add to Inventory'),
            ),
          const SizedBox(height: OhSpacing.sm),
          OutlinedButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Again'),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: OhRadii.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: OhSpacing.xs),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:openhearth_design/openhearth_design.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/label_id.dart';
import '../../../locations/presentation/controllers/location_controller.dart';

class ContainerLabelScreen extends ConsumerStatefulWidget {
  final String containerId;

  const ContainerLabelScreen({super.key, required this.containerId});

  @override
  ConsumerState<ContainerLabelScreen> createState() =>
      _ContainerLabelScreenState();
}

class _ContainerLabelScreenState extends ConsumerState<ContainerLabelScreen> {
  final _repaintKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareLabel() async {
    setState(() => _isSharing = true);
    try {
      final ctx = _repaintKey.currentContext;
      if (ctx == null) return;
      final renderObject = ctx.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        return;
      }

      final image = await renderObject.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/still_life_container_${widget.containerId.substring(0, 8)}.png',
      );
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path, mimeType: 'image/png'),
      ], subject: 'Still Life Container Label');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not share label: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final containerAsync = ref.watch(
      containerDetailProvider(widget.containerId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Container Label'),
        actions: [
          if (_isSharing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share label',
              onPressed: _shareLabel,
            ),
        ],
      ),
      body: containerAsync.when(
        data: (container) {
          if (container == null) {
            return const Center(child: Text('Container not found'));
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: OhRadii.lg,
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Still Life',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      QrImageView(
                        data: widget.containerId,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        container.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (container.type != null) ...[
                        const SizedBox(height: OhSpacing.xs),
                        Text(
                          container.type!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: OhSpacing.sm),
                      Text(
                        labelId(widget.containerId),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

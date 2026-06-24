import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

class SpeedDialFab extends StatefulWidget {
  final VoidCallback onPhoto;
  final VoidCallback onVoice;
  final VoidCallback onManual;

  const SpeedDialFab({
    super.key,
    required this.onPhoto,
    required this.onVoice,
    required this.onManual,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  OverlayEntry? _barrierEntry;
  OverlayEntry? _menuEntry;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: OhMotion.standard,
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _removeOverlays();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlays() {
    _barrierEntry?.remove();
    _barrierEntry = null;
    _menuEntry?.remove();
    _menuEntry = null;
  }

  void _showOverlays() {
    final overlay = Overlay.of(context);

    // Barrier behind everything — translucent so taps on buttons pass through.
    // We insert barrier first (bottom), then menu on top.
    final barrierEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: const SizedBox.expand(),
      ),
    );

    // Menu options rendered in the bottom-right corner.
    final menuEntry = OverlayEntry(
      builder: (_) => Positioned(
        right: 16,
        bottom: 80, // above main FAB
        child: ScaleTransition(
          scale: _scaleAnim,
          alignment: Alignment.bottomRight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DialOption(
                icon: Icons.camera_alt,
                label: 'Take photo',
                onTap: () {
                  _close();
                  widget.onPhoto();
                },
              ),
              const SizedBox(height: OhSpacing.sm),
              _DialOption(
                icon: Icons.mic,
                label: 'Describe it',
                onTap: () {
                  _close();
                  widget.onVoice();
                },
              ),
              const SizedBox(height: OhSpacing.sm),
              _DialOption(
                icon: Icons.edit,
                label: 'Enter manually',
                onTap: () {
                  _close();
                  widget.onManual();
                },
              ),
            ],
          ),
        ),
      ),
    );

    _barrierEntry = barrierEntry;
    _menuEntry = menuEntry;

    // Insert barrier at bottom, menu on top of it.
    overlay.insert(barrierEntry);
    overlay.insert(menuEntry, above: barrierEntry);
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      setState(() => _open = true);
      _controller.forward();
      _showOverlays();
    }
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _controller.reverse();
    _removeOverlays();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'speedDialMain',
      onPressed: _toggle,
      child: AnimatedRotation(
        turns: _open ? 0.125 : 0,
        duration: OhMotion.standard,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DialOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DialOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 2,
          borderRadius: OhRadii.md,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
        ),
        const SizedBox(width: OhSpacing.sm),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}

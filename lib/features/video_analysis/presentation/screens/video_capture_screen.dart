import 'package:camera/camera.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../locations/domain/entities/room.dart';
import '../../../locations/presentation/controllers/location_controller.dart';
import '../controllers/video_analysis_controller.dart';

class VideoCaptureScreen extends ConsumerStatefulWidget {
  final String? roomId;

  const VideoCaptureScreen({super.key, this.roomId});

  @override
  ConsumerState<VideoCaptureScreen> createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends ConsumerState<VideoCaptureScreen>
    with WidgetsBindingObserver {
  String? _selectedRoomId;
  bool _isImporting = false;

  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _cameraError = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.roomId;
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = true);
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
      });
    } catch (_) {
      if (mounted) setState(() => _cameraError = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start recording')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isRecordingVideo) return;
    try {
      final file = await controller.stopVideoRecording();
      setState(() => _isRecording = false);
      if (!mounted) return;
      ref
          .read(videoAnalysisControllerProvider.notifier)
          .startSession(file.path, _selectedRoomId);
      context.go('/video/processing');
    } catch (_) {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _importVideo() async {
    setState(() => _isImporting = true);
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null && mounted) {
        ref
            .read(videoAnalysisControllerProvider.notifier)
            .startSession(video.path, _selectedRoomId);
        context.go('/video/processing');
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Record Video'), centerTitle: true),
      body: Column(
        children: [
          // Room selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: roomsAsync.when(
              data: (rooms) => DropdownButtonFormField<String>(
                initialValue: _selectedRoomId,
                decoration: const InputDecoration(
                  labelText: 'Room (optional)',
                  border: OutlineInputBorder(
                    borderRadius: OhRadii.md,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No room selected'),
                  ),
                  ...rooms.map(
                    (Room room) => DropdownMenuItem<String>(
                      value: room.id,
                      child: Text(room.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedRoomId = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(
                'Could not load rooms',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ),

          // Camera preview
          Expanded(
            child: Padding(
              padding: OhSpacing.insetMd,
              child: ClipRRect(
                borderRadius: OhRadii.xl,
                child: _buildCameraPreview(colorScheme),
              ),
            ),
          ),

          // Bottom controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Import button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.tonal(
                        onPressed: _isImporting ? null : _importVideo,
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: OhSpacing.insetMd,
                        ),
                        child: _isImporting
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              )
                            : Icon(
                                Icons.photo_library_outlined,
                                color: colorScheme.onSecondaryContainer,
                              ),
                      ),
                      const SizedBox(height: OhSpacing.sm),
                      Text('Import', style: theme.textTheme.labelSmall),
                    ],
                  ),

                  // Record button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _cameraReady
                            ? (_isRecording ? _stopRecording : _startRecording)
                            : null,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _cameraReady
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withAlpha(80),
                              width: 4,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _cameraReady
                                  ? (_isRecording
                                        ? colorScheme.error.withAlpha(180)
                                        : colorScheme.error)
                                  : colorScheme.onSurface.withAlpha(40),
                              borderRadius: _isRecording
                                  ? OhRadii.md
                                  : BorderRadius.circular(40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: OhSpacing.sm),
                      Text(
                        _isRecording ? 'Stop' : 'Record',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _isRecording ? colorScheme.error : null,
                        ),
                      ),
                    ],
                  ),

                  // Spacer to balance layout
                  const SizedBox(width: 56),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(ColorScheme colorScheme) {
    if (_cameraError) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.no_photography_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Camera unavailable',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: OhSpacing.sm),
              Text(
                'Use Import to pick an existing video',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraController;
    if (!_cameraReady || controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        if (_isRecording)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: OhRadii.lg,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 10),
                  SizedBox(width: 6),
                  Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Hint overlay
        if (!_isRecording)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Slowly pan around the room to capture items',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

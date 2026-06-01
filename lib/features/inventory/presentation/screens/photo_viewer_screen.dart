import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/photo.dart';

/// Full-screen, zoomable photo viewer with swipe-between-photos support.
class PhotoViewerScreen extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.photos.length > 1
            ? Text('${_currentIndex + 1} / ${widget.photos.length}')
            : null,
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return _ZoomablePhoto(filePath: photo.filePath);
        },
      ),
    );
  }
}

class _ZoomablePhoto extends StatelessWidget {
  final String filePath;

  const _ZoomablePhoto({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: file.existsSync()
            ? Image.file(file, fit: BoxFit.contain)
            : const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
      ),
    );
  }
}

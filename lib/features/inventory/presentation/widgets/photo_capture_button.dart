import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoCaptureButton extends StatelessWidget {
  final void Function(String path, ImageSource source) onPhotoCaptured;

  const PhotoCaptureButton({super.key, required this.onPhotoCaptured});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => _showSourcePicker(context),
      icon: const Icon(Icons.add_a_photo_outlined),
      label: const Text('Add Photo'),
    );
  }

  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (picked != null) {
      onPhotoCaptured(picked.path, source);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/item_suggestion.dart';

Future<void> onVoiceAddItem(
  BuildContext context,
  WidgetRef ref, {
  String? roomId,
  String? containerId,
}) async {
  final voiceService = ref.read(voiceInputServiceProvider);

  // Check/request permission
  final ok = await voiceService.initialize();
  if (!context.mounted) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Microphone permission required for voice add.'),
      ),
    );
    return;
  }

  // Show listening dialog while collecting transcript
  String partialText = '';
  String? transcript;

  // Start listening before showing dialog so we don't miss the first words
  final listenFuture = voiceService.listen(onPartial: (p) => partialText = p);

  if (!context.mounted) return;

  // Show a dialog that reflects partial results
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Listening...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  partialText.isEmpty
                      ? 'Speak now — describe the item'
                      : partialText,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await voiceService.stop();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );

  if (!context.mounted) {
    await voiceService.stop();
    return;
  }

  // Wait for listen to complete (stop() triggers final result)
  try {
    transcript = await listenFuture;
  } finally {
    // Ensure dialog is dismissed even if listen() throws
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  if (transcript == null || !context.mounted) return;

  // Analyse transcript via LLM
  final analysisService = ref.read(itemPhotoAnalysisServiceProvider);
  final suggestion = await analysisService.analyzeVoice(transcript);
  if (!context.mounted) return;

  context.pushNamed(
    'addItem',
    queryParameters: {'roomId': ?roomId, 'containerId': ?containerId},
    extra: suggestion,
  );
}

Future<void> onPhotoAddItem(
  BuildContext context,
  WidgetRef ref, {
  String? roomId,
  String? containerId,
}) async {
  final picker = ImagePicker();
  final photo = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
  );
  if (photo == null || !context.mounted) return;

  final bytes = await photo.readAsBytes();
  final service = ref.read(itemPhotoAnalysisServiceProvider);
  final suggestion = await service.analyzePhoto(bytes);
  if (!context.mounted) return;

  final extra =
      suggestion?.copyWith(photoPath: photo.path) ??
      ItemSuggestion(photoPath: photo.path);
  context.pushNamed(
    'addItem',
    queryParameters: {'roomId': ?roomId, 'containerId': ?containerId},
    extra: extra,
  );
}

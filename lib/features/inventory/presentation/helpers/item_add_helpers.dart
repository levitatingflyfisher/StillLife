import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../data/services/item_photo_analysis_service.dart';
import '../../domain/entities/item_suggestion.dart';
import '../screens/shelf_review_screen.dart';

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
                  final navigator = Navigator.of(ctx);
                  await voiceService.stop();
                  navigator.pop();
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

  // Analyse transcript via LLM. Without a usable suggestion the manual
  // form still gets the transcript as notes — real data only, never a
  // fabricated suggestion.
  final analysisService = ref.read(itemPhotoAnalysisServiceProvider);
  final outcome = await analysisService.analyzeVoice(transcript);
  if (!context.mounted) return;

  _maybeExplainNoAi(context, outcome);

  final suggestion = switch (outcome) {
    AnalysisSuggestion(:final suggestion) => suggestion,
    // ShelfSuggestions never comes out of analyzeVoice; treated as no
    // suggestion so the transcript still lands in notes.
    NoAiConfigured() ||
    AnalysisFailed() ||
    ShelfSuggestions() => ItemSuggestion(notes: transcript),
  };

  context.pushNamed(
    'addItem',
    queryParameters: {'roomId': ?roomId, 'containerId': ?containerId},
    extra: suggestion,
  );
}

/// Says honestly — once, briefly — why the flow is falling through to the
/// manual form: no AI tier configured, or a configured tier that FAILED.
/// The failure branch must never be silent: a revoked key or a dead
/// server has to be distinguishable from "AI ran and found nothing".
void _maybeExplainNoAi(BuildContext context, AnalysisOutcome outcome) {
  final message = switch (outcome) {
    NoAiConfigured() =>
      'No AI provider configured — opening the manual form. '
          'Add one in Settings > AI Analysis.',
    AnalysisFailed(:final message) =>
      'AI analysis failed — opening the manual form. ($message)',
    _ => null,
  };
  if (message == null) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

/// How to interpret one captured photo: one item, or a whole shelf.
enum _PhotoAddMode { single, shelf }

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
  if (!context.mounted) return;

  // After capture the user chooses how to read the photo. Dismissing the
  // sheet abandons the flow — no analysis, no navigation.
  final mode = await showModalBottomSheet<_PhotoAddMode>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: const Text('Single item'),
            subtitle: const Text('One photo, one item'),
            onTap: () => Navigator.of(ctx).pop(_PhotoAddMode.single),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_outlined),
            title: const Text('Many items (shelf)'),
            subtitle: const Text('Identify every item in the photo'),
            onTap: () => Navigator.of(ctx).pop(_PhotoAddMode.shelf),
          ),
        ],
      ),
    ),
  );
  if (mode == null || !context.mounted) return;

  switch (mode) {
    case _PhotoAddMode.single:
      await _singlePhotoFlow(
        context,
        ref,
        photoPath: photo.path,
        bytes: bytes,
        roomId: roomId,
        containerId: containerId,
      );
    case _PhotoAddMode.shelf:
      await _shelfPhotoFlow(
        context,
        ref,
        photoPath: photo.path,
        bytes: bytes,
        roomId: roomId,
        containerId: containerId,
      );
  }
}

Future<void> _singlePhotoFlow(
  BuildContext context,
  WidgetRef ref, {
  required String photoPath,
  required Uint8List bytes,
  String? roomId,
  String? containerId,
}) async {
  final service = ref.read(itemPhotoAnalysisServiceProvider);
  final outcome = await service.analyzePhoto(bytes);
  if (!context.mounted) return;

  _maybeExplainNoAi(context, outcome);

  // The photo is kept either way; without a usable suggestion the user
  // lands on the manual form with just the photo attached. Bytes, not a
  // path: the add form attaches them to the saved item on every platform.
  final suggestion = switch (outcome) {
    AnalysisSuggestion(:final suggestion) => suggestion,
    // ShelfSuggestions never comes out of analyzePhoto (single-item path).
    NoAiConfigured() || AnalysisFailed() || ShelfSuggestions() => null,
  };
  _pushManualAddForm(
    context,
    suggestion: suggestion,
    photoPath: photoPath,
    bytes: bytes,
    roomId: roomId,
    containerId: containerId,
  );
}

Future<void> _shelfPhotoFlow(
  BuildContext context,
  WidgetRef ref, {
  required String photoPath,
  required Uint8List bytes,
  String? roomId,
  String? containerId,
}) async {
  final service = ref.read(itemPhotoAnalysisServiceProvider);
  final outcome = await service.analyzeShelfPhoto(bytes);
  if (!context.mounted) return;

  switch (outcome) {
    case ShelfSuggestions(:final suggestions) when suggestions.isNotEmpty:
      context.pushNamed(
        'shelfReview',
        extra: ShelfReviewArgs(
          suggestions: suggestions,
          photoBytes: bytes,
          roomId: roomId,
          containerId: containerId,
        ),
      );
    case ShelfSuggestions():
      // An honest empty shelf: say so and keep the photo via the manual
      // form instead of opening an empty review screen.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No items identified in the photo — opening the manual form.',
          ),
        ),
      );
      _pushManualAddForm(
        context,
        photoPath: photoPath,
        bytes: bytes,
        roomId: roomId,
        containerId: containerId,
      );
    case NoAiConfigured():
      // Same honest degradation the single-item flow established: explain
      // once, keep the photo, never open the review screen.
      _maybeExplainNoAi(context, outcome);
      _pushManualAddForm(
        context,
        photoPath: photoPath,
        bytes: bytes,
        roomId: roomId,
        containerId: containerId,
      );
    case AnalysisFailed():
      // Same degradation as no-AI, but the snackbar names the failure —
      // the message is the whole reason the typed outcome carries one.
      _maybeExplainNoAi(context, outcome);
      _pushManualAddForm(
        context,
        photoPath: photoPath,
        bytes: bytes,
        roomId: roomId,
        containerId: containerId,
      );
    case AnalysisSuggestion(:final suggestion):
      // analyzeShelfPhoto never returns a single suggestion; if it ever
      // did, degrade to the single-item add form rather than dropping it.
      _pushManualAddForm(
        context,
        suggestion: suggestion,
        photoPath: photoPath,
        bytes: bytes,
        roomId: roomId,
        containerId: containerId,
      );
  }
}

/// Opens the manual add form with the captured photo (and any suggestion)
/// riding along.
void _pushManualAddForm(
  BuildContext context, {
  ItemSuggestion? suggestion,
  required String photoPath,
  required Uint8List bytes,
  String? roomId,
  String? containerId,
}) {
  final extra =
      suggestion?.copyWith(photoPath: photoPath, photoBytes: bytes) ??
      ItemSuggestion(photoPath: photoPath, photoBytes: bytes);
  context.pushNamed(
    'addItem',
    queryParameters: {'roomId': ?roomId, 'containerId': ?containerId},
    extra: extra,
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:still_life/core/providers/repository_providers.dart';
import 'package:still_life/features/settings/presentation/controllers/on_device_models_controller.dart';
import 'package:still_life/services/ml/on_device/model_registry.dart';
import 'package:still_life/services/ml/on_device/nano_engine.dart';

/// "1.7 GB" / "546 MB" for download-size copy.
String formatModelSize(int bytes) => bytes >= 1000000000
    ? '${(bytes / 1e9).toStringAsFixed(1)} GB'
    : '${(bytes / 1e6).round()} MB';

/// The Tier-1 settings block: the three on-device rungs and their state.
/// Everything here is honest about what runs where — the bundled labeler
/// is always ready, VLM models exist only after an explicit verified
/// download, and Gemini Nano appears only on devices whose AICore admits
/// to having it.
class OnDeviceSection extends ConsumerWidget {
  const OnDeviceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = ref.watch(onDeviceSupportProvider);

    if (!support.supported) {
      return const ListTile(
        leading: Icon(Icons.phone_android_outlined),
        title: Text('Not available on this platform'),
        subtitle: Text(
          'On-device analysis runs in the Android app. This build always '
          'uses the configured tiers above.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListTile(
          leading: Icon(Icons.bolt_outlined),
          title: Text('Instant labeler — Ready'),
          subtitle: Text(
            'Bundled ~400-label recognizer. Coarse ("Chair", "Laptop") but '
            'instant, offline, and needs no download. Re-analyze later on a '
            'richer tier to add brand and value.',
          ),
        ),
        const _NanoTile(),
        for (final model in kOnDeviceModels) _ModelTile(model: model),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Everything in this section runs entirely on this phone — '
            'photos analyzed on-device never leave it. Model downloads come '
            'from Hugging Face (ggml-org, Apache-2.0) and are verified '
            'against pinned checksums before use.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _NanoTile extends ConsumerWidget {
  const _NanoTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(nanoStatusProvider).valueOrNull;

    final (subtitle, trailing) = switch (status) {
      null => ('Checking device support…', null),
      NanoStatus.unsupported => (
        'Not supported on this device (needs AICore — Pixel 9/10-class).',
        null,
      ),
      NanoStatus.downloadable => (
        'Supported. Set up downloads the shared system model via Google '
        'Play — nothing happens without this step.',
        TextButton(
          onPressed: () async {
            final nano = ref.read(onDeviceSupportProvider).nano;
            if (nano == null) return;
            final messenger = ScaffoldMessenger.of(context);
            await nano.requestSetup();
            ref.invalidate(nanoStatusProvider);
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Requested Gemini Nano provisioning — Android downloads '
                  'it in the background.',
                ),
              ),
            );
          },
          child: const Text('Set up'),
        ),
      ),
      NanoStatus.downloading => ('Provisioning in the background…', null),
      NanoStatus.available => ('Ready — free on-device analysis.', null),
    };

    return ListTile(
      leading: const Icon(Icons.auto_awesome_outlined),
      title: const Text('Gemini Nano'),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}

class _ModelTile extends ConsumerWidget {
  final OnDeviceModel model;
  const _ModelTile({required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status =
        ref.watch(onDeviceModelsControllerProvider).valueOrNull?[model.id] ??
        const ModelNotDownloaded();
    final controller = ref.read(onDeviceModelsControllerProvider.notifier);
    final size = formatModelSize(model.totalBytes);

    return switch (status) {
      ModelNotDownloaded() => ListTile(
        leading: const Icon(Icons.download_outlined),
        title: Text(model.displayName),
        subtitle: Text('$size · ${model.ramNote}'),
        trailing: FilledButton(
          onPressed: () => _confirmDownload(context, controller),
          child: const Text('Download'),
        ),
      ),
      ModelDownloading(:final progress) => ListTile(
        leading: const Icon(Icons.downloading_outlined),
        title: Text(model.displayName),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(value: progress),
        ),
        trailing: TextButton(
          onPressed: () => controller.cancel(model),
          child: const Text('Cancel'),
        ),
      ),
      ModelInstalled() => ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(model.displayName),
        subtitle: Text('Downloaded · $size on disk · ${model.ramNote}'),
        trailing: TextButton(
          onPressed: () => _confirmDelete(context, controller),
          child: const Text('Delete'),
        ),
      ),
      ModelDownloadFailed(:final message) => ListTile(
        leading: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(model.displayName),
        subtitle: Text(
          'Download failed: $message',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        trailing: FilledButton(
          onPressed: () => controller.download(model),
          child: const Text('Retry'),
        ),
      ),
    };
  }

  Future<void> _confirmDownload(
    BuildContext context,
    OnDeviceModelsController controller,
  ) async {
    final size = formatModelSize(model.totalBytes);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download ${model.displayName}?'),
        content: Text(
          'One-time $size download from Hugging Face '
          '(${model.sourceRepo}, ${model.license}). Wi-Fi recommended.\n\n'
          '${model.ramNote}.\n\n'
          'Once downloaded, photo analysis with this model runs fully '
          'offline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      // Fire-and-forget: the tile re-renders from controller state.
      // ignore: unawaited_futures
      controller.download(model);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OnDeviceModelsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${model.displayName}?'),
        content: Text(
          'Frees ${formatModelSize(model.totalBytes)}. You can download it '
          'again any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete model'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await controller.delete(model);
    }
  }
}

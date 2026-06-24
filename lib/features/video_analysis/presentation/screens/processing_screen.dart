import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/analysis_session.dart';
import '../controllers/video_analysis_controller.dart';
import '../widgets/detected_item_card.dart';
import '../widgets/processing_stage_indicator.dart';

class ProcessingScreen extends ConsumerWidget {
  const ProcessingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(videoAnalysisControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Processing')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: OhSpacing.md),
              Text('No active session', style: theme.textTheme.titleMedium),
              const SizedBox(height: OhSpacing.lg),
              FilledButton.tonal(
                onPressed: () => context.go('/video/capture'),
                child: const Text('Start New Scan'),
              ),
            ],
          ),
        ),
      );
    }

    final objects = session.detectedObjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyzing Video'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Stage indicator
          ProcessingStageIndicator(currentStatus: session.status),

          const Divider(height: 1),

          // Progress bar
          if (session.totalFrames > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: OhRadii.sm,
                    child: LinearProgressIndicator(
                      value: session.progress,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: OhSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Frame ${session.processedFrames} of ${session.totalFrames}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${(session.progress * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Animated item counter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: AnimatedSwitcher(
              duration: OhMotion.deliberate,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Column(
                key: ValueKey(objects.length),
                children: [
                  Text(
                    '${objects.length}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    objects.length == 1 ? 'item found' : 'items found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Scrollable list of detected items
          Expanded(
            child: objects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: OhSpacing.md),
                        Text(
                          'Searching for items...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: objects.length,
                    itemBuilder: (context, index) {
                      // Show newest items first.
                      final obj = objects[objects.length - 1 - index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DetectedItemCard(object: obj),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Bottom bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Cancel but keep partial results if any.
                    if (objects.isNotEmpty) {
                      ref
                          .read(videoAnalysisControllerProvider.notifier)
                          .updateStatus(AnalysisStatus.reviewing);
                      context.go('/video/review');
                    } else {
                      ref
                          .read(videoAnalysisControllerProvider.notifier)
                          .reset();
                      context.go('/video/capture');
                    }
                  },
                  child: Text(objects.isNotEmpty ? 'Stop & Review' : 'Cancel'),
                ),
              ),
              if (session.status == AnalysisStatus.reviewing ||
                  session.isComplete) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.go('/video/review'),
                    child: const Text('Review Items'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

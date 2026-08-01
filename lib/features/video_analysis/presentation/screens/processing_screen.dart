import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/analysis_session.dart';
import '../controllers/video_analysis_controller.dart';
import '../widgets/analysis_cost_notice.dart';
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

    // Honest terminal states — never an infinite spinner.
    if (session.status == AnalysisStatus.noAiConfigured) {
      return _NoAiConfiguredScreen(colorScheme: colorScheme, theme: theme);
    }
    if (session.status == AnalysisStatus.failed) {
      return _FailedScreen(
        message: session.failureMessage,
        colorScheme: colorScheme,
        theme: theme,
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

          // Cost honesty: once the quality gate has chosen the frames, the
          // number of analysis calls (and whose compute pays) is known.
          if (session.selectedFrames > 0)
            AnalysisCostNotice(
              calls: session.selectedFrames,
              tier: session.providerTier,
            ),

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

          // Animated item counter — the running MERGED count during
          // analysis; the reviewed list once complete.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: AnimatedSwitcher(
              duration: OhMotion.deliberate,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Column(
                key: ValueKey(session.itemsSoFar),
                children: [
                  Text(
                    '${session.itemsSoFar}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    session.itemsSoFar == 1 ? 'item found' : 'items found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Scrollable list of detected items. Empty + still running =
          // live spinner; empty + terminal = an honest "nothing found"
          // (an all-frames-failed run also lands here — the spinner must
          // never claim a finished search is ongoing).
          Expanded(
            child: objects.isEmpty
                ? Center(
                    child: session.isProcessing
                        ? Column(
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
                          )
                        : Padding(
                            padding: OhSpacing.insetLg,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_outlined,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: OhSpacing.md),
                                Text(
                                  'No items found in this walkthrough',
                                  style: theme.textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: OhSpacing.sm),
                                Text(
                                  'Nothing was recognized — or the analysis '
                                  'calls failed. Try panning slower, with '
                                  'more light, or check the AI settings.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
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
                    // Stop but keep partial results if any (they stream
                    // in mid-run now); a plain cancel also closes the
                    // session-log row instead of stranding 'processing'.
                    final notifier = ref.read(
                      videoAnalysisControllerProvider.notifier,
                    );
                    if (objects.isNotEmpty) {
                      notifier.stopAndReview();
                      context.go('/video/review');
                    } else {
                      notifier.cancelAnalysis();
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

/// The honest no-AI state: explains, points at Settings, never spins.
class _NoAiConfiguredScreen extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _NoAiConfiguredScreen({
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyzing Video'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: OhSpacing.insetLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: OhSpacing.md),
              Text(
                'No AI provider configured',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: OhSpacing.sm),
              Text(
                'Video analysis needs an AI tier to identify items. '
                'Add one in Settings > AI Analysis, then scan again.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: OhSpacing.lg),
              FilledButton(
                onPressed: () => context.push('/settings/llm'),
                child: const Text('Open AI Settings'),
              ),
              const SizedBox(height: OhSpacing.sm),
              TextButton(
                onPressed: () => context.go('/video/capture'),
                child: const Text('Back to Capture'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The honest failure state: names what broke and offers the way back.
class _FailedScreen extends StatelessWidget {
  final String? message;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _FailedScreen({
    required this.message,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyzing Video'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: OhSpacing.insetLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: OhSpacing.md),
              Text(
                'Analysis failed',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: OhSpacing.sm),
                Text(
                  message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: OhSpacing.lg),
              FilledButton(
                onPressed: () => context.go('/video/capture'),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

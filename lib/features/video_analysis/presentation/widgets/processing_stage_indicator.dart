import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../domain/entities/analysis_session.dart';

/// The pipeline stages to display (excludes recording and complete).
const _pipelineStages = [
  AnalysisStatus.extracting,
  AnalysisStatus.detecting,
  AnalysisStatus.tracking,
  AnalysisStatus.selecting,
  AnalysisStatus.classifying,
  AnalysisStatus.enhancing,
  AnalysisStatus.reviewing,
];

/// Horizontal stepper showing progress through the analysis pipeline.
class ProcessingStageIndicator extends StatelessWidget {
  final AnalysisStatus currentStatus;

  const ProcessingStageIndicator({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentIndex = _pipelineStages.indexOf(currentStatus);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _pipelineStages.length; i++) ...[
            if (i > 0)
              Container(
                width: 24,
                height: 2,
                color: i <= currentIndex
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            _StageChip(
              stage: _pipelineStages[i],
              isCompleted: i < currentIndex,
              isCurrent: i == currentIndex,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final AnalysisStatus stage;
  final bool isCompleted;
  final bool isCurrent;
  final ColorScheme colorScheme;

  const _StageChip({
    required this.stage,
    required this.isCompleted,
    required this.isCurrent,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color bgColor;
    final Color fgColor;
    if (isCompleted) {
      bgColor = colorScheme.primaryContainer;
      fgColor = colorScheme.onPrimaryContainer;
    } else if (isCurrent) {
      bgColor = colorScheme.primary;
      fgColor = colorScheme.onPrimary;
    } else {
      bgColor = colorScheme.surfaceContainerHighest;
      fgColor = colorScheme.onSurfaceVariant;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: OhMotion.deliberate,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: isCurrent
                ? null
                : Border.all(
                    color: isCompleted
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check_rounded, size: 18, color: fgColor)
                : isCurrent
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fgColor,
                    ),
                  )
                : Icon(Icons.circle_outlined, size: 14, color: fgColor),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 64,
          child: Text(
            stage.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isCurrent
                  ? colorScheme.primary
                  : isCompleted
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

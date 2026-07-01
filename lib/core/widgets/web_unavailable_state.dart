import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// Calm empty-state shown where a native-only feature would be on the web.
///
/// Honest by design: it names the feature, says plainly that it needs the
/// Android app, and (optionally) points at what DOES work on web instead.
/// Mirrors the app's existing empty-state idiom (circled icon + title +
/// supporting line).
class WebUnavailableState extends StatelessWidget {
  final IconData icon;
  final String featureName;
  final String explanation;

  const WebUnavailableState({
    super.key,
    required this.icon,
    required this.featureName,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: OhSpacing.insetLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: OhSpacing.lg),
            Text(
              '$featureName isn\'t available on web',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OhSpacing.sm),
            Text(
              explanation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

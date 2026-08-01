import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/appraisal_providers.dart';
import '../../../../core/utils/safe_external_url.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../domain/entities/appraisal.dart';
import '../../domain/entities/appraisal_source.dart';
import '../controllers/appraisal_controller.dart';

/// Bottom sheet that runs an appraisal, shows sources, and allows refresh.
class AppraiseSheet extends ConsumerStatefulWidget {
  final Item item;
  final AppraisalMode mode;
  const AppraiseSheet({super.key, required this.item, required this.mode});

  @override
  ConsumerState<AppraiseSheet> createState() => _AppraiseSheetState();
}

class _AppraiseSheetState extends ConsumerState<AppraiseSheet> {
  bool _triggered = false;

  /// Id of the appraisal the user applied to the item, if any. A refresh
  /// produces a new appraisal id, which naturally re-arms the button.
  String? _appliedId;

  ({String itemId, AppraisalMode mode}) get _key =>
      (itemId: widget.item.id, mode: widget.mode);

  @override
  Widget build(BuildContext context) {
    final asyncApp = ref.watch(appraisalControllerProvider(_key));
    return SafeArea(
      child: Padding(
        padding: OhSpacing.insetMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.mode.label} estimate',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            asyncApp.when(
              data: (a) => _buildBody(context, a),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Could not fetch estimate: $e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    asyncApp.valueOrNull == null
                        ? 'Run estimate'
                        : 'Refresh estimate',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Appraisal? a) {
    if (a == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Tap "Run estimate" to search current market prices for this '
          'item.\nEstimates run on Anthropic (Claude) — via your Claude '
          'API key or a Pro account.',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!a.hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No comparable listings were found.',
          textAlign: TextAlign.center,
        ),
      );
    }
    final fmt = NumberFormat.simpleCurrency(name: a.currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            fmt.format(a.valueCents / 100),
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        const SizedBox(height: OhSpacing.sm),
        const Text('Confidence'),
        const SizedBox(height: OhSpacing.xs),
        LinearProgressIndicator(value: a.confidence.clamp(0.0, 1.0)),
        const SizedBox(height: OhSpacing.md),
        if (a.sources.isNotEmpty) ...[
          Text('Sources', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: OhSpacing.xs),
          ...a.sources.map((s) => _SourceTile(source: s)),
        ],
        const SizedBox(height: OhSpacing.md),
        _buildApplyRow(context, a),
      ],
    );
  }

  /// The value loop: an explicit, per-appraisal write-back. Never automatic —
  /// nothing touches the item until the user taps.
  Widget _buildApplyRow(BuildContext context, Appraisal a) {
    final isResale = widget.mode == AppraisalMode.resale;
    final applied = _appliedId == a.id;
    return Row(
      children: [
        Expanded(
          child: Text(
            isResale
                ? "Applies this estimate as the item's current value."
                : "Applies this estimate as the item's replacement cost.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: OhSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: applied ? null : () => _apply(a),
          icon: Icon(applied ? Icons.check : Icons.save_alt, size: 18),
          label: Text(applied ? 'Applied' : 'Apply to item'),
        ),
      ],
    );
  }

  Future<void> _apply(Appraisal a) async {
    final res = await ref.read(appraisalRepositoryProvider).applyToItem(a);
    if (!mounted) return;
    res.when(
      success: (_) => setState(() => _appliedId = a.id),
      failure: (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not apply: $f'))),
    );
  }

  Future<void> _refresh() async {
    setState(() => _triggered = true);
    await ref
        .read(appraisalControllerProvider(_key).notifier)
        .appraise(widget.item, forceRefresh: _triggered);
  }
}

class _SourceTile extends StatelessWidget {
  final AppraisalSource source;
  const _SourceTile({required this.source});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(source.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(source.url, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: source.price == null
          ? null
          : Text(NumberFormat.simpleCurrency(name: 'USD').format(source.price)),
      onTap: () async {
        // The URL is model output — only plain web URLs may launch
        // (an injected intent:// or javascript: URI must go nowhere).
        final uri = safeExternalHttpUri(source.url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}

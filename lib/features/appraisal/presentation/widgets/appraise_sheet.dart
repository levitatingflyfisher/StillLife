import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
          'Tap "Run estimate" to search current market prices for this item.',
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
            fmt.format(a.value),
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
      ],
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
        final uri = Uri.tryParse(source.url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/account.dart';

/// Shows monthly token usage as a percentage, raw ratio, and reset
/// countdown. Clamps the progress bar at 100% so a runaway usage number
/// (e.g. server-side bug) can't paint outside the widget.
class UsageMeter extends StatelessWidget {
  final Account account;

  const UsageMeter({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final pct = (account.usageFraction * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly usage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('$pct%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: account.usageFraction.clamp(0.0, 1.0)),
        const SizedBox(height: 4),
        Text('${account.tokensUsedMonth} / ${account.tokensMonthCap} tokens'),
        Text('Resets ${_formatDate(account.monthResetAt)}'),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'soon';
    return 'in $diff day${diff == 1 ? '' : 's'}';
  }
}

import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../services/database/database.dart' show Receipt;

/// Read-only viewer for a stored receipt: the full-size photo plus the
/// scanned text behind an expander. No editing, no linking.
class ReceiptViewerScreen extends StatelessWidget {
  final Receipt receipt;

  const ReceiptViewerScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      if (receipt.storeName != null) receipt.storeName!,
      if (receipt.purchaseDate != null) receipt.purchaseDate!.toShortDate(),
      if (receipt.totalAmountCents != null) receipt.totalAmountCents!.centsToCurrency(),
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt'), centerTitle: true),
      body: ListView(
        padding: OhSpacing.insetMd,
        children: [
          if (details.isNotEmpty) ...[
            Text(details, style: theme.textTheme.titleMedium),
            const SizedBox(height: OhSpacing.md),
          ],
          if (receipt.photoBytes != null)
            ClipRRect(
              borderRadius: OhRadii.lg,
              child: Image.memory(receipt.photoBytes!, fit: BoxFit.contain),
            )
          else
            Text(
              'No photo stored for this receipt.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (receipt.ocrText != null && receipt.ocrText!.trim().isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Scanned text'),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      receipt.ocrText!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

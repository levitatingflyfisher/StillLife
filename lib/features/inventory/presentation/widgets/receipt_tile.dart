import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/currency_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../controllers/receipt_controller.dart';
import '../screens/receipt_viewer_screen.dart';

/// Small "Receipt" tile for the item detail screen: store · date · total
/// with a thumbnail; tap opens [ReceiptViewerScreen]. Renders nothing
/// while loading or when the linked row is gone.
class ReceiptTile extends ConsumerWidget {
  final String receiptId;

  const ReceiptTile({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(itemReceiptProvider(receiptId)).valueOrNull;
    if (receipt == null) return const SizedBox.shrink();

    final details = [
      if (receipt.storeName != null) receipt.storeName!,
      if (receipt.purchaseDate != null) receipt.purchaseDate!.toShortDate(),
      if (receipt.totalAmountCents != null) receipt.totalAmountCents!.centsToCurrency(),
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: receipt.photoBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(
                  receipt.photoBytes!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.receipt_long_outlined),
        title: const Text('Receipt'),
        subtitle: details.isEmpty ? null : Text(details),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReceiptViewerScreen(receipt: receipt),
          ),
        ),
      ),
    );
  }
}

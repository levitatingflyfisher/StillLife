import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../services/database/database.dart';

/// The receipt row an item links to via `Items.receiptId`, or null when
/// the row is gone (soft-deleted or never synced to this device).
///
/// Reads the drift row directly — receipts have no domain entity; the
/// detail screen only renders what the import persisted.
final itemReceiptProvider = FutureProvider.family<Receipt?, String>((
  ref,
  receiptId,
) {
  return ref.watch(databaseProvider).receiptDao.getReceipt(receiptId);
});

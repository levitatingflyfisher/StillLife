import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/notification_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../services/notifications/notification_service.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';

/// Streams all items that are below their low-stock threshold.
final lowStockItemsProvider = StreamProvider<List<Item>>((ref) {
  return ref.watch(itemRepositoryProvider).watchLowStockItems();
});

/// Handles quantity decrements + fires low-stock notifications.
final quantityControllerProvider = Provider<QuantityController>((ref) {
  return QuantityController(
    repo: ref.read(itemRepositoryProvider),
    notifications: ref.read(notificationServiceProvider),
  );
});

class QuantityController {
  final ItemRepository repo;
  final NotificationService notifications;

  QuantityController({required this.repo, required this.notifications});

  /// Decrement [itemId]'s quantity by 1. Fires a low-stock notification when
  /// the result is at or below the item's threshold. Silently ignores failures.
  Future<void> decrement(String itemId) async {
    final result = await repo.decrementQuantity(itemId);
    Item? updated;
    result.when(success: (item) => updated = item, failure: (_) {});
    if (updated != null && updated!.isLowStock) {
      await notifications.showLowStockAlert(
        itemId: updated!.id,
        itemName: updated!.name,
        quantity: updated!.quantity!,
        threshold: updated!.lowStockThreshold!,
      );
    }
  }
}

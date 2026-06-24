import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/quantity_controller.dart';
import '../../../../core/providers/repository_providers.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(lowStockItemsProvider);
    final ctrl = ref.read(quantityControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock'),
        actions: [
          itemsAsync.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : TextButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export Shopping List'),
                    onPressed: () async {
                      final csv = await ref
                          .read(csvExportServiceProvider)
                          .exportShoppingListToCsv();
                      final bytes = Uint8List.fromList(utf8.encode(csv));
                      await Share.shareXFiles([
                        XFile.fromData(
                          bytes,
                          mimeType: 'text/csv',
                          name: 'shopping_list.csv',
                        ),
                      ]);
                    },
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 48),
                  SizedBox(height: 8),
                  Text('No items are running low'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final qty = item.quantity!;
              final qtyStr = qty % 1 == 0
                  ? qty.toInt().toString()
                  : qty.toStringAsFixed(1);
              final unit = item.quantityUnit != null
                  ? ' ${item.quantityUnit}'
                  : '';
              return ListTile(
                title: Text(item.name),
                subtitle: item.categoryName != null
                    ? Text(item.categoryName!)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$qtyStr$unit',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => ctrl.decrement(item.id),
                      tooltip: '−1',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

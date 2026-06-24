import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/store_integration/domain/entities/receipt.dart';

void main() {
  group('ReceiptLineItem', () {
    test('stores description and price', () {
      const item = ReceiptLineItem(
        description: 'Milk 2%',
        price: 3.99,
        quantity: 1,
      );
      expect(item.description, 'Milk 2%');
      expect(item.price, 3.99);
      expect(item.quantity, 1);
    });

    test('equality based on all fields', () {
      const a = ReceiptLineItem(description: 'Bread', price: 2.50);
      const b = ReceiptLineItem(description: 'Bread', price: 2.50);
      expect(a, equals(b));
    });
  });

  group('Receipt', () {
    final now = DateTime(2025, 6, 15);

    test('has required fields', () {
      final receipt = Receipt(
        id: 'r-1',
        photoPath: '/photos/receipt1.jpg',
        createdAt: now,
      );
      expect(receipt.id, 'r-1');
      expect(receipt.photoPath, '/photos/receipt1.jpg');
      expect(receipt.itemId, isNull);
      expect(receipt.lineItems, isEmpty);
    });

    test('copyWith preserves original fields', () {
      final receipt = Receipt(
        id: 'r-1',
        photoPath: '/photos/receipt1.jpg',
        storeName: 'Target',
        totalAmount: 42.99,
        createdAt: now,
      );

      final updated = receipt.copyWith(itemId: 'item-1', storeName: 'Walmart');

      expect(updated.id, 'r-1');
      expect(updated.photoPath, '/photos/receipt1.jpg');
      expect(updated.itemId, 'item-1');
      expect(updated.storeName, 'Walmart');
      expect(updated.totalAmount, 42.99);
    });

    test('equality based on id', () {
      final a = Receipt(id: 'r-1', photoPath: '/a.jpg', createdAt: now);
      final b = Receipt(
        id: 'r-1',
        photoPath: '/b.jpg',
        storeName: 'Different',
        createdAt: now,
      );
      expect(a, equals(b));
    });
  });

  group('PriceHistoryEntry', () {
    test('stores price and source', () {
      final entry = PriceHistoryEntry(
        id: 'p-1',
        itemId: 'item-1',
        price: 299.99,
        source: 'amazon',
        recordedAt: DateTime(2025, 6, 15),
      );
      expect(entry.price, 299.99);
      expect(entry.source, 'amazon');
    });

    test('equality based on id', () {
      final a = PriceHistoryEntry(
        id: 'p-1',
        itemId: 'item-1',
        price: 100.0,
        source: 'manual',
        recordedAt: DateTime(2025, 1, 1),
      );
      final b = PriceHistoryEntry(
        id: 'p-1',
        itemId: 'item-1',
        price: 200.0,
        source: 'amazon',
        recordedAt: DateTime(2025, 6, 1),
      );
      expect(a, equals(b));
    });
  });
}

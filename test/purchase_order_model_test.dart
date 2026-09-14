import 'package:flutter_test/flutter_test.dart';

import 'package:electrical_shop/features/purchase_orders/models/purchase_order_model.dart';

void main() {
  group('PurchaseOrderItemModel', () {
    test('calculates line totals correctly', () {
      final item = PurchaseOrderItemModel(
        id: 'item-1',
        productId: 'product-1',
        productName: 'Wire',
        sku: 'SKU-1',
        quantityOrdered: 10,
        quantityReceived: 0,
        unitCost: 100,
        gstPercent: 18,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(item.lineSubtotal, 1000);
      expect(item.lineGstAmount, 180);
      expect(item.lineTotal, 1180);
      expect(item.remainingQuantity, 10);
    });
  });

  group('PurchaseOrderModel helpers', () {
    test('clamps received quantity to remaining quantity', () {
      expect(
        PurchaseOrderModel.clampReceivedQuantity(
          requestedQuantity: 15,
          remainingQuantity: 8,
        ),
        8,
      );
    });

    test('resolves completed status after full receive', () {
      expect(
        PurchaseOrderModel.resolveStatusAfterReceive(
          currentStatus: PurchaseOrderStatus.ordered,
          anyReceived: true,
          allCompleted: true,
        ),
        PurchaseOrderStatus.completed,
      );
    });

    test('resolves partially received status after partial receive', () {
      expect(
        PurchaseOrderModel.resolveStatusAfterReceive(
          currentStatus: PurchaseOrderStatus.ordered,
          anyReceived: true,
          allCompleted: false,
        ),
        PurchaseOrderStatus.partiallyReceived,
      );
    });

    test('retains terminal status during receive attempts', () {
      expect(
        PurchaseOrderModel.resolveStatusAfterReceive(
          currentStatus: PurchaseOrderStatus.cancelled,
          anyReceived: true,
          allCompleted: true,
        ),
        PurchaseOrderStatus.cancelled,
      );
    });
  });
}

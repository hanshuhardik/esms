import 'package:electrical_shop/features/billing/models/bill_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillItemModel', () {
    test('calculates line total correctly', () {
      final item = BillItemModel(
        productId: 'p1',
        productName: 'Wire',
        sku: 'SKU1',
        quantity: 2,
        sellingPrice: 150,
        discount: 20,
      );

      expect(item.lineSubtotal, 300);
      expect(item.lineTotal, 280);
      expect(item.canSellAgainstStock(2), isTrue);
      expect(item.canSellAgainstStock(1), isFalse);
    });
  });

  group('BillModel', () {
    final items = [
      BillItemModel(
        productId: 'p1',
        productName: 'Wire',
        sku: 'SKU1',
        quantity: 2,
        sellingPrice: 100,
        discount: 10,
      ),
      BillItemModel(
        productId: 'p2',
        productName: 'Switch',
        sku: 'SKU2',
        quantity: 1,
        sellingPrice: 50,
      ),
    ];

    test('calculates subtotal and total correctly', () {
      final subtotal = BillModel.calculateSubtotal(items);
      final total = BillModel.calculateTotal(subtotal: subtotal, discount: 15);

      expect(subtotal, 240);
      expect(total, 225);
    });

    test('formats sequential bill numbers', () {
      expect(BillModel.nextSequence(7), 8);
      expect(BillModel.formatBillNumber('BILL', 8), 'BILL-000008');
      expect(BillModel.formatBillNumber('', 8), 'BILL-000008');
    });

    test('guards stock validation', () {
      expect(
        BillModel.canSellAgainstStock(requestedQuantity: 2, availableStock: 2),
        isTrue,
      );
      expect(
        BillModel.canSellAgainstStock(requestedQuantity: 3, availableStock: 2),
        isFalse,
      );
    });

    test('keeps finalized status detection correct', () {
      expect(BillStatus.completed.isFinalized, isTrue);
      expect(BillStatus.cancelled.isFinalized, isFalse);
    });
  });
}

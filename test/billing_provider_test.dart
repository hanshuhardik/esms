import 'package:electrical_shop/features/billing/models/bill_model.dart';
import 'package:electrical_shop/features/billing/providers/billing_provider.dart';
import 'package:electrical_shop/features/products/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

ProductModel buildProduct({
  required String id,
  required String name,
  required String sku,
  required double sellingPrice,
  required int stockQuantity,
  ProductStatus status = ProductStatus.active,
}) {
  return ProductModel(
    id: id,
    sku: sku,
    name: name,
    brandId: 'brand-1',
    categoryId: 'category-1',
    unit: ProductUnit.piece,
    purchasePrice: sellingPrice / 2,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity,
    minimumStock: 1,
    supplierId: 'supplier-1',
    locationId: 'location-1',
    status: status,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('BillingNotifier cart behavior', () {
    test(
      'adds the same product once and increases quantity instead of duplicating',
      () {
        final notifier = BillingNotifier();
        final product = buildProduct(
          id: 'p1',
          name: 'Copper Wire',
          sku: 'WIRE-1',
          sellingPrice: 125.5,
          stockQuantity: 3,
        );

        expect(notifier.addProduct(product), isNull);
        expect(notifier.addProduct(product), isNull);

        expect(notifier.state.items, hasLength(1));
        expect(notifier.state.items.single.quantity, 2);
        expect(notifier.state.items.single.availableStock, 3);
        expect(notifier.subtotal, closeTo(251.0, 1e-10));
      },
    );

    test('prevents quantity from exceeding available stock', () {
      final notifier = BillingNotifier();
      final product = buildProduct(
        id: 'p2',
        name: 'Switch',
        sku: 'SW-1',
        sellingPrice: 50,
        stockQuantity: 1,
      );

      expect(notifier.addProduct(product), isNull);
      expect(notifier.addProduct(product), isNotNull);
      expect(notifier.increaseQuantity(product.id), isNotNull);
      expect(notifier.state.items.single.quantity, 1);
    });

    test('can increase, decrease, remove, and clear cart items', () {
      final notifier = BillingNotifier();
      final product = buildProduct(
        id: 'p3',
        name: 'Socket',
        sku: 'SOC-1',
        sellingPrice: 20,
        stockQuantity: 4,
      );

      expect(notifier.addProduct(product), isNull);
      expect(notifier.increaseQuantity(product.id), isNull);
      expect(notifier.state.items.single.quantity, 2);

      notifier.decreaseQuantity(product.id);
      expect(notifier.state.items.single.quantity, 1);

      notifier.decreaseQuantity(product.id);
      expect(notifier.state.items, isEmpty);

      expect(notifier.addProduct(product), isNull);
      notifier.removeItem(product.id);
      expect(notifier.state.items, isEmpty);

      notifier.addProduct(product);
      final previousDraftId = notifier.state.draftId;
      notifier.clearCart();
      expect(notifier.state.items, isEmpty);
      expect(notifier.state.draftId, isNot(previousDraftId));
    });

    test('rejects inactive products and invalid discount input', () {
      final notifier = BillingNotifier();
      final inactiveProduct = buildProduct(
        id: 'p4',
        name: 'Disabled Item',
        sku: 'DIS-1',
        sellingPrice: 10,
        stockQuantity: 5,
        status: ProductStatus.inactive,
      );

      expect(notifier.addProduct(inactiveProduct), isNotNull);

      notifier.updateDiscount('abc');
      expect(notifier.state.billDiscount, 0);

      notifier.updateDiscount('-10');
      expect(notifier.state.billDiscount, 0);
    });
  });

  group('BillingNotifier finalize validation', () {
    test('rejects empty carts and excessive discounts', () {
      final notifier = BillingNotifier();
      expect(notifier.validateForFinalize(), isNotNull);

      final product = buildProduct(
        id: 'p5',
        name: 'Breaker',
        sku: 'BRK-1',
        sellingPrice: 100,
        stockQuantity: 2,
      );

      expect(notifier.addProduct(product), isNull);
      notifier.updateDiscount('150');
      expect(notifier.validateForFinalize(), isNotNull);

      notifier.updateDiscount('10');
      expect(notifier.validateForFinalize(), isNull);
    });

    test('calculates decimal line totals and clamps invalid quantities', () {
      expect(
        BillItemModel.calculateLineTotal(
          quantity: 3,
          sellingPrice: 0.1,
          discount: 0,
        ),
        closeTo(0.3, 1e-10),
      );

      expect(
        BillItemModel.calculateLineTotal(
          quantity: 0,
          sellingPrice: 99,
          discount: 10,
        ),
        0,
      );

      expect(
        BillItemModel.calculateLineTotal(
          quantity: -2,
          sellingPrice: 25,
          discount: 0,
        ),
        0,
      );
    });
  });
}

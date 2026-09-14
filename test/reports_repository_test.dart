import 'package:electrical_shop/features/billing/models/bill_model.dart';
import 'package:electrical_shop/features/expenses/models/expense_model.dart';
import 'package:electrical_shop/features/products/models/product_model.dart';
import 'package:electrical_shop/features/purchase_orders/models/purchase_order_model.dart';
import 'package:electrical_shop/features/reports/models/report_models.dart';
import 'package:electrical_shop/features/reports/repositories/reports_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BillModel buildBill({
  required String id,
  required DateTime createdAt,
  required BillPaymentMethod paymentMethod,
  required List<BillItemModel> items,
  double discount = 0,
}) {
  final subtotal = BillModel.calculateSubtotal(items);
  return BillModel(
    id: id,
    billNumber: 'BILL-${id.toUpperCase()}',
    billSequence: 1,
    items: items,
    subtotal: subtotal,
    discount: discount,
    total: BillModel.calculateTotal(subtotal: subtotal, discount: discount),
    paymentMethod: paymentMethod,
    customerName: null,
    customerPhone: null,
    createdBy: 'Tester',
    createdAt: createdAt,
    status: BillStatus.completed,
  );
}

ExpenseModel buildExpense({
  required String id,
  required DateTime date,
  required ExpenseCategory category,
  required double amount,
}) {
  return ExpenseModel(
    id: id,
    title: category.label,
    description: null,
    amount: amount,
    category: category,
    paymentMethod: ExpensePaymentMethod.cash,
    expenseDate: date,
    createdBy: 'Tester',
    createdAt: date,
    updatedAt: date,
  );
}

ProductModel buildProduct({
  required String id,
  required String name,
  required double purchasePrice,
  required double sellingPrice,
  required int stockQuantity,
  ProductStatus status = ProductStatus.active,
}) {
  return ProductModel(
    id: id,
    sku: id.toUpperCase(),
    name: name,
    brandId: 'brand',
    categoryId: 'category',
    unit: ProductUnit.piece,
    purchasePrice: purchasePrice,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity,
    minimumStock: 1,
    supplierId: 'supplier',
    locationId: 'location',
    status: status,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );
}

PurchaseOrderModel buildPurchaseOrder({
  required String id,
  required DateTime createdAt,
  required PurchaseOrderStatus status,
  required double grandTotal,
}) {
  return PurchaseOrderModel(
    id: id,
    orderNumber: 'PO-$id',
    supplierId: 'supplier',
    supplierName: 'Supplier',
    status: status,
    items: const [],
    notes: null,
    subtotal: grandTotal,
    gstAmount: 0,
    grandTotal: grandTotal,
    createdById: 'u1',
    createdByName: 'Tester',
    receivedById: null,
    receivedByName: null,
    receivedAt: null,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

void main() {
  final now = DateTime(2026, 8, 13, 10);
  final bills = [
    buildBill(
      id: 'b1',
      createdAt: DateTime(2026, 8, 13),
      paymentMethod: BillPaymentMethod.cash,
      items: [
        BillItemModel(
          productId: 'p1',
          productName: 'Wire',
          sku: 'W1',
          quantity: 2,
          sellingPrice: 100,
          discount: 10,
        ),
      ],
      discount: 5,
    ),
    buildBill(
      id: 'b2',
      createdAt: DateTime(2026, 8, 12),
      paymentMethod: BillPaymentMethod.upi,
      items: [
        BillItemModel(
          productId: 'p2',
          productName: 'Switch',
          sku: 'S1',
          quantity: 1,
          sellingPrice: 50,
        ),
      ],
    ),
  ];

  final expenses = [
    buildExpense(
      id: 'e1',
      date: DateTime(2026, 8, 13),
      category: ExpenseCategory.electricity,
      amount: 1000,
    ),
    buildExpense(
      id: 'e2',
      date: DateTime(2026, 8, 12),
      category: ExpenseCategory.transport,
      amount: 250,
    ),
  ];

  final products = [
    buildProduct(
      id: 'p1',
      name: 'Wire',
      purchasePrice: 60,
      sellingPrice: 100,
      stockQuantity: 10,
    ),
    buildProduct(
      id: 'p2',
      name: 'Switch',
      purchasePrice: 30,
      sellingPrice: 50,
      stockQuantity: 0,
    ),
  ];

  final purchaseOrders = [
    buildPurchaseOrder(
      id: 'po1',
      createdAt: DateTime(2026, 8, 13),
      status: PurchaseOrderStatus.completed,
      grandTotal: 1200,
    ),
    buildPurchaseOrder(
      id: 'po2',
      createdAt: DateTime(2026, 8, 12),
      status: PurchaseOrderStatus.ordered,
      grandTotal: 800,
    ),
  ];

  group('ReportsRepository', () {
    test('calculates sales aggregation and payment method distribution', () {
      final snapshot = ReportsRepository.buildSnapshot(
        bills: bills,
        expenses: expenses,
        products: products,
        purchaseOrders: purchaseOrders,
        preset: ReportsDatePreset.thisMonth,
        now: now,
      );

      expect(snapshot.salesReport.totalSales, closeTo(235, 1e-10));
      expect(snapshot.salesReport.billCount, 2);
      expect(snapshot.salesReport.itemsSold, 3);
      expect(snapshot.salesReport.salesByPaymentMethod, hasLength(2));
      expect(
        snapshot.salesReport.salesByPaymentMethod.first.label,
        anyOf('Cash', 'UPI'),
      );
    });

    test('calculates expense aggregation and category totals', () {
      final snapshot = ReportsRepository.buildSnapshot(
        bills: bills,
        expenses: expenses,
        products: products,
        purchaseOrders: purchaseOrders,
        preset: ReportsDatePreset.thisMonth,
        now: now,
      );

      expect(snapshot.expenseReport.totalExpenses, 1250);
      expect(snapshot.expenseReport.expenseCount, 2);
      expect(snapshot.expenseReport.expensesByCategory, hasLength(2));
      expect(
        snapshot.expenseReport.expensesByCategory
            .firstWhere((value) => value.label == 'Electricity')
            .value,
        1000,
      );
    });

    test('calculates profit using current product purchase prices', () {
      final snapshot = ReportsRepository.buildSnapshot(
        bills: bills,
        expenses: expenses,
        products: products,
        purchaseOrders: purchaseOrders,
        preset: ReportsDatePreset.thisMonth,
        now: now,
      );

      expect(snapshot.profitReport.revenue, closeTo(235, 1e-10));
      expect(snapshot.profitReport.costOfGoodsSold, closeTo(150, 1e-10));
      expect(snapshot.profitReport.expenses, 1250);
      expect(snapshot.profitReport.netProfit, closeTo(-1165, 1e-10));
    });

    test('filters by date range and calculates range summary', () {
      final snapshot = ReportsRepository.buildSnapshot(
        bills: bills,
        expenses: expenses,
        products: products,
        purchaseOrders: purchaseOrders,
        preset: ReportsDatePreset.custom,
        customRange: DateTimeRange(
          start: DateTime(2026, 8, 13),
          end: DateTime(2026, 8, 13),
        ),
        now: now,
      );

      expect(snapshot.selectedRangeSummary.sales, closeTo(185, 1e-10));
      expect(snapshot.selectedRangeSummary.expenses, 1000);
      expect(snapshot.selectedRangeSummary.billCount, 1);
      expect(snapshot.selectedRangeSummary.itemsSold, 2);
    });

    test('calculates inventory valuation and purchase totals', () {
      final snapshot = ReportsRepository.buildSnapshot(
        bills: bills,
        expenses: expenses,
        products: products,
        purchaseOrders: purchaseOrders,
        preset: ReportsDatePreset.thisMonth,
        now: now,
      );

      expect(snapshot.inventoryReport.totalProducts, 2);
      expect(snapshot.inventoryReport.totalStockQuantity, 10);
      expect(snapshot.inventoryReport.lowStockProducts, 0);
      expect(snapshot.inventoryReport.outOfStockProducts, 1);
      expect(snapshot.inventoryReport.inventoryValue, 600);
      expect(snapshot.inventoryReport.potentialSalesValue, 1000);
      expect(snapshot.purchaseReport.totalPurchaseOrders, 2);
      expect(snapshot.purchaseReport.totalPurchaseValue, 2000);
      expect(snapshot.purchaseReport.pendingPurchaseOrders, 1);
      expect(snapshot.purchaseReport.receivedPurchaseOrders, 1);
    });
  });
}

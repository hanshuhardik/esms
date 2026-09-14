import 'package:flutter/material.dart';

import '../../../features/billing/models/bill_model.dart';
import '../../../features/expenses/models/expense_model.dart';
import '../../../features/products/models/product_model.dart';
import '../../../features/purchase_orders/models/purchase_order_model.dart';
import '../models/report_models.dart';
import '../services/reports_service.dart';

class ReportsRepository {
  ReportsRepository._();

  static Stream<List<BillModel>> watchBills() => ReportsService.fetchBills()
      .asStream()
      .asyncExpand((items) => Stream.value(items));

  static Stream<List<ExpenseModel>> watchExpenses() =>
      ReportsService.fetchExpenses().asStream().asyncExpand(
        (items) => Stream.value(items),
      );

  static Stream<List<ProductModel>> watchProducts() =>
      ReportsService.fetchProducts().asStream().asyncExpand(
        (items) => Stream.value(items),
      );

  static Stream<List<PurchaseOrderModel>> watchPurchaseOrders() =>
      ReportsService.fetchPurchaseOrders().asStream().asyncExpand(
        (items) => Stream.value(items),
      );

  static DateTimeRange resolveRange(
    ReportsDatePreset preset, {
    DateTimeRange? customRange,
    DateTime? now,
  }) {
    final current = _dateOnly(now ?? DateTime.now());

    switch (preset) {
      case ReportsDatePreset.today:
        return DateTimeRange(start: current, end: current);
      case ReportsDatePreset.yesterday:
        final yesterday = current.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      case ReportsDatePreset.thisWeek:
        final start = current.subtract(Duration(days: current.weekday - 1));
        return DateTimeRange(start: start, end: current);
      case ReportsDatePreset.thisMonth:
        final start = DateTime(current.year, current.month, 1);
        return DateTimeRange(start: start, end: current);
      case ReportsDatePreset.custom:
        if (customRange == null) {
          final start = DateTime(current.year, current.month, 1);
          return DateTimeRange(start: start, end: current);
        }
        return DateTimeRange(
          start: _dateOnly(customRange.start),
          end: _dateOnly(customRange.end),
        );
    }
  }

  static ReportsSnapshot buildSnapshot({
    required List<BillModel> bills,
    required List<ExpenseModel> expenses,
    required List<ProductModel> products,
    required List<PurchaseOrderModel> purchaseOrders,
    required ReportsDatePreset preset,
    DateTimeRange? customRange,
    DateTime? now,
  }) {
    final current = _dateOnly(now ?? DateTime.now());
    final selectedRange = resolveRange(
      preset,
      customRange: customRange,
      now: current,
    );
    final todayRange = DateTimeRange(start: current, end: current);
    final weekRange = DateTimeRange(
      start: current.subtract(Duration(days: current.weekday - 1)),
      end: current,
    );
    final monthRange = DateTimeRange(
      start: DateTime(current.year, current.month, 1),
      end: current,
    );

    final productLookup = {for (final product in products) product.id: product};

    final todayMetrics = _periodSummary(
      bills: bills,
      expenses: expenses,
      products: productLookup,
      range: todayRange,
    );
    final weekMetrics = _periodSummary(
      bills: bills,
      expenses: expenses,
      products: productLookup,
      range: weekRange,
    );
    final monthMetrics = _periodSummary(
      bills: bills,
      expenses: expenses,
      products: productLookup,
      range: monthRange,
    );

    final totalBills = bills.length;
    final totalItemsSold = bills.fold<int>(
      0,
      (total, bill) =>
          total + bill.items.fold<int>(0, (sum, item) => sum + item.quantity),
    );

    final selectedBills = _filterBillsByRange(bills, selectedRange);
    final selectedExpenses = _filterExpensesByRange(expenses, selectedRange);
    final selectedPurchaseOrders = _filterPurchaseOrdersByRange(
      purchaseOrders,
      selectedRange,
    );

    final selectedSalesReport = _buildSalesReport(
      bills: selectedBills,
      products: productLookup,
      range: selectedRange,
    );
    final selectedExpenseReport = _buildExpenseReport(
      expenses: selectedExpenses,
      range: selectedRange,
    );
    final selectedProfitReport = _buildProfitReport(
      bills: selectedBills,
      expenses: selectedExpenses,
      products: productLookup,
    );
    final selectedInventoryReport = _buildInventoryReport(products);
    final selectedPurchaseReport = _buildPurchaseReport(
      purchaseOrders: selectedPurchaseOrders,
      range: selectedRange,
    );
    final salesVsExpenses = _buildSalesVsExpensesSeries(
      bills: selectedBills,
      expenses: selectedExpenses,
      range: selectedRange,
    );

    return ReportsSnapshot(
      selectedRange: selectedRange,
      overview: ReportsDashboardOverview(
        today: todayMetrics,
        week: weekMetrics,
        month: monthMetrics,
        totalBills: totalBills,
        totalItemsSold: totalItemsSold,
      ),
      selectedRangeSummary: ReportsRangeSummary(
        sales: selectedSalesReport.totalSales,
        expenses: selectedExpenseReport.totalExpenses,
        profit: selectedProfitReport.netProfit,
        billCount: selectedSalesReport.billCount,
        itemsSold: selectedSalesReport.itemsSold,
      ),
      salesReport: selectedSalesReport,
      expenseReport: selectedExpenseReport,
      profitReport: selectedProfitReport,
      inventoryReport: selectedInventoryReport,
      purchaseReport: selectedPurchaseReport,
      salesVsExpenses: salesVsExpenses,
    );
  }

  static ReportsPeriodSummary _periodSummary({
    required List<BillModel> bills,
    required List<ExpenseModel> expenses,
    required Map<String, ProductModel> products,
    required DateTimeRange range,
  }) {
    final sales = _salesTotalForBills(bills, products, range);
    final expenseTotal = _expensesTotalForRange(expenses, range);
    final cogs = _costOfGoodsForBills(bills, products, range).costOfGoodsSold;
    return ReportsPeriodSummary(
      sales: sales,
      expenses: expenseTotal,
      profit: sales - cogs - expenseTotal,
    );
  }

  static ReportsSalesReport _buildSalesReport({
    required List<BillModel> bills,
    required Map<String, ProductModel> products,
    required DateTimeRange range,
  }) {
    final totalSales = _salesTotalForBills(bills, products, range);
    final billCount = bills.length;
    final itemsSold = bills.fold<int>(
      0,
      (total, bill) =>
          total + bill.items.fold<int>(0, (sum, item) => sum + item.quantity),
    );
    final averageBillValue = billCount == 0 ? 0.0 : totalSales / billCount;

    return ReportsSalesReport(
      totalSales: totalSales,
      billCount: billCount,
      averageBillValue: averageBillValue,
      itemsSold: itemsSold,
      salesByDay: _buildSalesByDay(bills, range, products),
      salesByPaymentMethod: _buildSalesByPaymentMethod(bills, products, range),
      topProducts: _buildTopProducts(bills, products, range),
    );
  }

  static ReportsExpenseReport _buildExpenseReport({
    required List<ExpenseModel> expenses,
    required DateTimeRange range,
  }) {
    final totalExpenses = _expensesTotalForRange(expenses, range);
    final expenseCount = expenses.length;
    final expensesByCategory = _buildNamedTotals(
      expenses.map(
        (expense) => ReportsNamedValue(
          label: expense.category.label,
          value: expense.amount,
        ),
      ),
    );

    return ReportsExpenseReport(
      totalExpenses: totalExpenses,
      expenseCount: expenseCount,
      expensesByCategory: expensesByCategory,
      expensesByDay: _buildExpensesByDay(expenses, range),
      highestExpenseCategories: expensesByCategory.take(3).toList(),
    );
  }

  static ReportsProfitReport _buildProfitReport({
    required List<BillModel> bills,
    required List<ExpenseModel> expenses,
    required Map<String, ProductModel> products,
  }) {
    final revenue = bills.fold<double>(0, (sum, bill) => sum + bill.total);
    final cost = _costOfGoodsForBills(bills, products, null);
    final expenseTotal = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final netProfit = revenue - cost.costOfGoodsSold - expenseTotal;
    return ReportsProfitReport(
      revenue: revenue,
      costOfGoodsSold: cost.costOfGoodsSold,
      expenses: expenseTotal,
      netProfit: netProfit,
      unresolvedCostItems: cost.unresolvedCostItems,
      limitationNote:
          'Cost of goods sold uses current product purchase prices because the current schema does not store historical cost snapshots on bill items.',
    );
  }

  static ReportsInventoryReport _buildInventoryReport(
    List<ProductModel> products,
  ) {
    final totalProducts = products.length;
    final totalStockQuantity = products.fold<int>(
      0,
      (sum, product) => sum + product.stockQuantity,
    );
    final lowStockProducts = products
        .where((product) => product.isLowStock)
        .length;
    final outOfStockProducts = products
        .where((product) => product.isOutOfStock)
        .length;
    final inventoryValue = products.fold<double>(
      0,
      (sum, product) => sum + (product.purchasePrice * product.stockQuantity),
    );
    final potentialSalesValue = products.fold<double>(
      0,
      (sum, product) => sum + (product.sellingPrice * product.stockQuantity),
    );

    return ReportsInventoryReport(
      totalProducts: totalProducts,
      totalStockQuantity: totalStockQuantity,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
      inventoryValue: inventoryValue,
      potentialSalesValue: potentialSalesValue,
    );
  }

  static ReportsPurchaseReport _buildPurchaseReport({
    required List<PurchaseOrderModel> purchaseOrders,
    required DateTimeRange range,
  }) {
    final totalPurchaseOrders = purchaseOrders.length;
    final totalPurchaseValue = purchaseOrders.fold<double>(
      0,
      (sum, order) => sum + order.grandTotal,
    );
    final pendingPurchaseOrders = purchaseOrders
        .where(
          (order) =>
              order.status != PurchaseOrderStatus.completed &&
              order.status != PurchaseOrderStatus.cancelled,
        )
        .length;
    final receivedPurchaseOrders = purchaseOrders
        .where((order) => order.status == PurchaseOrderStatus.completed)
        .length;

    return ReportsPurchaseReport(
      totalPurchaseOrders: totalPurchaseOrders,
      totalPurchaseValue: totalPurchaseValue,
      pendingPurchaseOrders: pendingPurchaseOrders,
      receivedPurchaseOrders: receivedPurchaseOrders,
      purchaseTotalsByDay: _buildPurchaseByDay(purchaseOrders, range),
    );
  }

  static List<ReportsDailyValue> _buildSalesByDay(
    List<BillModel> bills,
    DateTimeRange range,
    Map<String, ProductModel> products,
  ) {
    final days = _daysInRange(range);
    return days
        .map(
          (day) => ReportsDailyValue(
            date: day,
            sales: _salesTotalForBills(
              bills,
              products,
              DateTimeRange(start: day, end: day),
            ),
            expenses: 0,
            purchases: 0,
          ),
        )
        .toList();
  }

  static List<ReportsDailyValue> _buildExpensesByDay(
    List<ExpenseModel> expenses,
    DateTimeRange range,
  ) {
    final days = _daysInRange(range);
    return days
        .map(
          (day) => ReportsDailyValue(
            date: day,
            sales: 0,
            expenses: _expensesTotalForRange(
              expenses,
              DateTimeRange(start: day, end: day),
            ),
            purchases: 0,
          ),
        )
        .toList();
  }

  static List<ReportsDailyValue> _buildPurchaseByDay(
    List<PurchaseOrderModel> purchaseOrders,
    DateTimeRange range,
  ) {
    final days = _daysInRange(range);
    return days
        .map(
          (day) => ReportsDailyValue(
            date: day,
            sales: 0,
            expenses: 0,
            purchases: _purchaseTotalForRange(
              purchaseOrders,
              DateTimeRange(start: day, end: day),
            ),
          ),
        )
        .toList();
  }

  static List<ReportsDailyValue> _buildSalesVsExpensesSeries({
    required List<BillModel> bills,
    required List<ExpenseModel> expenses,
    required DateTimeRange range,
  }) {
    final days = _daysInRange(range);
    return days
        .map(
          (day) => ReportsDailyValue(
            date: day,
            sales: _salesTotalForBills(
              bills,
              const {},
              DateTimeRange(start: day, end: day),
            ),
            expenses: _expensesTotalForRange(
              expenses,
              DateTimeRange(start: day, end: day),
            ),
            purchases: 0,
          ),
        )
        .toList();
  }

  static List<ReportsNamedValue> _buildSalesByPaymentMethod(
    List<BillModel> bills,
    Map<String, ProductModel> products,
    DateTimeRange range,
  ) {
    final totals = <String, double>{};
    for (final bill in _filterBillsByRange(bills, range)) {
      totals[bill.paymentMethod.label] =
          (totals[bill.paymentMethod.label] ?? 0) + bill.total;
    }

    return totals.entries
        .map((entry) => ReportsNamedValue(label: entry.key, value: entry.value))
        .toList()
      ..sort((left, right) => right.value.compareTo(left.value));
  }

  static List<ReportsNamedValue> _buildNamedTotals(
    Iterable<ReportsNamedValue> values,
  ) {
    final totals = <String, double>{};
    for (final value in values) {
      totals[value.label] = (totals[value.label] ?? 0) + value.value;
    }

    return totals.entries
        .map((entry) => ReportsNamedValue(label: entry.key, value: entry.value))
        .toList()
      ..sort((left, right) => right.value.compareTo(left.value));
  }

  static List<ReportsTopProduct> _buildTopProducts(
    List<BillModel> bills,
    Map<String, ProductModel> products,
    DateTimeRange range,
  ) {
    final aggregates = <String, _TopProductAggregate>{};
    for (final bill in _filterBillsByRange(bills, range)) {
      for (final item in bill.items) {
        final product = products[item.productId];
        final costPerUnit = product?.purchasePrice ?? 0;
        final effectiveRevenue = _billItemEffectiveRevenue(bill, item);
        final aggregate = aggregates.putIfAbsent(
          item.productId,
          () => _TopProductAggregate(
            productId: item.productId,
            productName: item.productName,
            sku: item.sku,
          ),
        );
        aggregate.quantitySold += item.quantity;
        aggregate.revenue += effectiveRevenue;
        aggregate.costOfGoodsSold += costPerUnit * item.quantity.toDouble();
      }
    }

    final result =
        aggregates.values
            .map(
              (aggregate) => ReportsTopProduct(
                productId: aggregate.productId,
                productName: aggregate.productName,
                sku: aggregate.sku,
                quantitySold: aggregate.quantitySold,
                revenue: aggregate.revenue,
                costOfGoodsSold: aggregate.costOfGoodsSold,
              ),
            )
            .toList()
          ..sort((left, right) {
            final quantityDiff = right.quantitySold.compareTo(
              left.quantitySold,
            );
            if (quantityDiff != 0) {
              return quantityDiff;
            }

            return right.revenue.compareTo(left.revenue);
          });

    return result.take(5).toList();
  }

  static double _salesTotalForBills(
    List<BillModel> bills,
    Map<String, ProductModel> products,
    DateTimeRange? range,
  ) {
    return _filterBillsByRange(
      bills,
      range,
    ).fold<double>(0, (sum, bill) => sum + bill.total);
  }

  static double _expensesTotalForRange(
    List<ExpenseModel> expenses,
    DateTimeRange range,
  ) {
    return _filterExpensesByRange(
      expenses,
      range,
    ).fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  static double _purchaseTotalForRange(
    List<PurchaseOrderModel> purchaseOrders,
    DateTimeRange range,
  ) {
    return _filterPurchaseOrdersByRange(
      purchaseOrders,
      range,
    ).fold<double>(0, (sum, order) => sum + order.grandTotal);
  }

  static List<BillModel> _filterBillsByRange(
    List<BillModel> bills,
    DateTimeRange? range,
  ) {
    if (range == null) {
      return bills;
    }

    return bills
        .where((bill) => _isWithinRange(bill.createdAt, range))
        .toList();
  }

  static List<ExpenseModel> _filterExpensesByRange(
    List<ExpenseModel> expenses,
    DateTimeRange range,
  ) {
    return expenses
        .where((expense) => expense.isWithinRange(range.start, range.end))
        .toList();
  }

  static List<PurchaseOrderModel> _filterPurchaseOrdersByRange(
    List<PurchaseOrderModel> purchaseOrders,
    DateTimeRange range,
  ) {
    return purchaseOrders
        .where((order) => _isWithinRange(order.createdAt, range))
        .toList();
  }

  static bool _isWithinRange(DateTime value, DateTimeRange range) {
    final date = _dateOnly(value);
    final start = _dateOnly(range.start);
    final end = _dateOnly(range.end);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static List<DateTime> _daysInRange(DateTimeRange range) {
    final start = _dateOnly(range.start);
    final end = _dateOnly(range.end);
    final days = <DateTime>[];

    var cursor = start;
    while (!cursor.isAfter(end)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    return days;
  }

  static ({double costOfGoodsSold, int unresolvedCostItems})
  _costOfGoodsForBills(
    List<BillModel> bills,
    Map<String, ProductModel> products,
    DateTimeRange? range,
  ) {
    var cost = 0.0;
    var unresolved = 0;

    for (final bill in _filterBillsByRange(bills, range)) {
      for (final item in bill.items) {
        final product = products[item.productId];
        if (product == null) {
          unresolved += 1;
          continue;
        }

        cost += product.purchasePrice * item.quantity;
      }
    }

    return (costOfGoodsSold: cost, unresolvedCostItems: unresolved);
  }

  static double _billItemEffectiveRevenue(BillModel bill, BillItemModel item) {
    final subtotal = bill.subtotal;
    if (bill.discount <= 0 || subtotal <= 0) {
      return item.lineTotal;
    }

    final proportionalDiscount = bill.discount * (item.lineSubtotal / subtotal);
    return (item.lineSubtotal - proportionalDiscount).clamp(0, double.infinity);
  }
}

class _TopProductAggregate {
  final String productId;
  final String productName;
  final String sku;
  int quantitySold = 0;
  double revenue = 0;
  double costOfGoodsSold = 0;

  _TopProductAggregate({
    required this.productId,
    required this.productName,
    required this.sku,
  });
}

import 'package:flutter/material.dart';

enum ReportsDatePreset {
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  custom('Custom');

  const ReportsDatePreset(this.label);

  final String label;
}

class ReportsPeriodSummary {
  final double sales;
  final double expenses;
  final double profit;

  const ReportsPeriodSummary({
    required this.sales,
    required this.expenses,
    required this.profit,
  });
}

class ReportsDashboardOverview {
  final ReportsPeriodSummary today;
  final ReportsPeriodSummary week;
  final ReportsPeriodSummary month;
  final int totalBills;
  final int totalItemsSold;

  const ReportsDashboardOverview({
    required this.today,
    required this.week,
    required this.month,
    required this.totalBills,
    required this.totalItemsSold,
  });
}

class ReportsRangeSummary {
  final double sales;
  final double expenses;
  final double profit;
  final int billCount;
  final int itemsSold;

  const ReportsRangeSummary({
    required this.sales,
    required this.expenses,
    required this.profit,
    required this.billCount,
    required this.itemsSold,
  });
}

class ReportsDailyValue {
  final DateTime date;
  final double sales;
  final double expenses;
  final double purchases;

  const ReportsDailyValue({
    required this.date,
    required this.sales,
    required this.expenses,
    required this.purchases,
  });
}

class ReportsNamedValue {
  final String label;
  final double value;
  final int count;

  const ReportsNamedValue({
    required this.label,
    required this.value,
    this.count = 0,
  });
}

class ReportsTopProduct {
  final String productId;
  final String productName;
  final String sku;
  final int quantitySold;
  final double revenue;
  final double costOfGoodsSold;

  const ReportsTopProduct({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantitySold,
    required this.revenue,
    required this.costOfGoodsSold,
  });
}

class ReportsSalesReport {
  final double totalSales;
  final int billCount;
  final double averageBillValue;
  final int itemsSold;
  final List<ReportsDailyValue> salesByDay;
  final List<ReportsNamedValue> salesByPaymentMethod;
  final List<ReportsTopProduct> topProducts;

  const ReportsSalesReport({
    required this.totalSales,
    required this.billCount,
    required this.averageBillValue,
    required this.itemsSold,
    required this.salesByDay,
    required this.salesByPaymentMethod,
    required this.topProducts,
  });
}

class ReportsExpenseReport {
  final double totalExpenses;
  final int expenseCount;
  final List<ReportsNamedValue> expensesByCategory;
  final List<ReportsDailyValue> expensesByDay;
  final List<ReportsNamedValue> highestExpenseCategories;

  const ReportsExpenseReport({
    required this.totalExpenses,
    required this.expenseCount,
    required this.expensesByCategory,
    required this.expensesByDay,
    required this.highestExpenseCategories,
  });
}

class ReportsProfitReport {
  final double revenue;
  final double costOfGoodsSold;
  final double expenses;
  final double netProfit;
  final int unresolvedCostItems;
  final String limitationNote;

  const ReportsProfitReport({
    required this.revenue,
    required this.costOfGoodsSold,
    required this.expenses,
    required this.netProfit,
    required this.unresolvedCostItems,
    required this.limitationNote,
  });
}

class ReportsInventoryReport {
  final int totalProducts;
  final int totalStockQuantity;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double inventoryValue;
  final double potentialSalesValue;

  const ReportsInventoryReport({
    required this.totalProducts,
    required this.totalStockQuantity,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.inventoryValue,
    required this.potentialSalesValue,
  });
}

class ReportsPurchaseReport {
  final int totalPurchaseOrders;
  final double totalPurchaseValue;
  final int pendingPurchaseOrders;
  final int receivedPurchaseOrders;
  final List<ReportsDailyValue> purchaseTotalsByDay;

  const ReportsPurchaseReport({
    required this.totalPurchaseOrders,
    required this.totalPurchaseValue,
    required this.pendingPurchaseOrders,
    required this.receivedPurchaseOrders,
    required this.purchaseTotalsByDay,
  });
}

class ReportsSnapshot {
  final DateTimeRange selectedRange;
  final ReportsDashboardOverview overview;
  final ReportsRangeSummary selectedRangeSummary;
  final ReportsSalesReport salesReport;
  final ReportsExpenseReport expenseReport;
  final ReportsProfitReport profitReport;
  final ReportsInventoryReport inventoryReport;
  final ReportsPurchaseReport purchaseReport;
  final List<ReportsDailyValue> salesVsExpenses;

  const ReportsSnapshot({
    required this.selectedRange,
    required this.overview,
    required this.selectedRangeSummary,
    required this.salesReport,
    required this.expenseReport,
    required this.profitReport,
    required this.inventoryReport,
    required this.purchaseReport,
    required this.salesVsExpenses,
  });
}

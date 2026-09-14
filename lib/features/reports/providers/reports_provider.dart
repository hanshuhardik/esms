import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/billing/models/bill_model.dart';
import '../../../features/expenses/models/expense_model.dart';
import '../../../features/products/models/product_model.dart';
import '../../../features/purchase_orders/models/purchase_order_model.dart';
import '../models/report_models.dart';
import '../repositories/reports_repository.dart';

class ReportsState {
  final List<BillModel> bills;
  final List<ExpenseModel> expenses;
  final List<ProductModel> products;
  final List<PurchaseOrderModel> purchaseOrders;
  final ReportsDatePreset preset;
  final DateTimeRange? customRange;
  final bool isLoading;
  final String? errorMessage;

  static const Object _unset = Object();

  const ReportsState({
    this.bills = const [],
    this.expenses = const [],
    this.products = const [],
    this.purchaseOrders = const [],
    this.preset = ReportsDatePreset.thisMonth,
    this.customRange,
    this.isLoading = false,
    this.errorMessage,
  });

  ReportsState copyWith({
    List<BillModel>? bills,
    List<ExpenseModel>? expenses,
    List<ProductModel>? products,
    List<PurchaseOrderModel>? purchaseOrders,
    ReportsDatePreset? preset,
    Object? customRange = _unset,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return ReportsState(
      bills: bills ?? this.bills,
      expenses: expenses ?? this.expenses,
      products: products ?? this.products,
      purchaseOrders: purchaseOrders ?? this.purchaseOrders,
      preset: preset ?? this.preset,
      customRange: customRange == _unset
          ? this.customRange
          : customRange as DateTimeRange?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>(
  (ref) => ReportsNotifier(),
);

class ReportsNotifier extends StateNotifier<ReportsState> {
  ReportsNotifier() : super(const ReportsState());

  bool _loaded = false;

  Future<void> loadReports({bool forceReload = false}) async {
    if (_loaded && !forceReload) {
      return;
    }

    _loaded = true;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await Future.wait<dynamic>([
        ReportsRepository.watchBills().first,
        ReportsRepository.watchExpenses().first,
        ReportsRepository.watchProducts().first,
        ReportsRepository.watchPurchaseOrders().first,
      ]);

      state = state.copyWith(
        bills: results[0] as List<BillModel>,
        expenses: results[1] as List<ExpenseModel>,
        products: results[2] as List<ProductModel>,
        purchaseOrders: results[3] as List<PurchaseOrderModel>,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      _loaded = false;
    }
  }

  void setPreset(ReportsDatePreset preset) {
    state = state.copyWith(preset: preset);
  }

  void setCustomRange(DateTimeRange? range) {
    state = state.copyWith(
      preset: ReportsDatePreset.custom,
      customRange: range,
    );
  }

  void clearCustomRange() {
    state = state.copyWith(customRange: null);
  }

  ReportsSnapshot get snapshot {
    return ReportsRepository.buildSnapshot(
      bills: state.bills,
      expenses: state.expenses,
      products: state.products,
      purchaseOrders: state.purchaseOrders,
      preset: state.preset,
      customRange: state.customRange,
    );
  }
}

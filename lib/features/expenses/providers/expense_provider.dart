import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

class ExpenseState {
  final List<ExpenseModel> expenses;
  final bool isLoading;
  final bool isSubmitting;
  final String searchQuery;
  final ExpenseCategory? categoryFilter;
  final DateTimeRange? dateRange;
  final String? errorMessage;

  static const Object _unset = Object();

  const ExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.searchQuery = '',
    this.categoryFilter,
    this.dateRange,
    this.errorMessage,
  });

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    bool? isLoading,
    bool? isSubmitting,
    String? searchQuery,
    ExpenseCategory? categoryFilter,
    Object? dateRange = _unset,
    Object? errorMessage = _unset,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      dateRange: dateRange == _unset
          ? this.dateRange
          : dateRange as DateTimeRange?,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>(
  (ref) => ExpenseNotifier(),
);

final expenseDetailsProvider = FutureProvider.family<ExpenseModel, String>((
  ref,
  expenseId,
) async {
  final result = await ExpenseRepository.getExpense(expenseId);

  if (result.isFailure || result.data == null) {
    throw Exception(result.error ?? 'Failed to load expense.');
  }

  return result.data!;
});

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  ExpenseNotifier() : super(const ExpenseState());

  StreamSubscription<List<ExpenseModel>>? _subscription;
  bool _loaded = false;

  void loadExpenses({bool forceReload = false}) {
    if (_loaded && !forceReload) {
      return;
    }

    _loaded = true;
    state = state.copyWith(isLoading: true, errorMessage: null);

    _subscription?.cancel();
    _subscription = ExpenseRepository.getExpenses().listen(
      (expenses) {
        state = state.copyWith(
          expenses: expenses,
          isLoading: false,
          errorMessage: null,
        );
      },
      onError: (Object error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
        _loaded = false;
      },
    );
  }

  void updateSearch(String value) {
    state = state.copyWith(searchQuery: value.trim());
  }

  void setCategoryFilter(ExpenseCategory? category) {
    state = state.copyWith(categoryFilter: category);
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: range);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      categoryFilter: null,
      dateRange: null,
    );
  }

  List<ExpenseModel> get filteredExpenses {
    return ExpenseRepository.filterExpenses(
      state.expenses,
      searchQuery: state.searchQuery,
      category: state.categoryFilter,
      dateRange: state.dateRange,
    );
  }

  ExpenseDashboardSummary get summary {
    return ExpenseRepository.summarizeExpenses(state.expenses);
  }

  Future<Result<ExpenseModel>> saveExpense({
    required ExpenseModel expense,
    required bool isEdit,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final result = isEdit
        ? await ExpenseRepository.updateExpense(expense)
        : await ExpenseRepository.createExpense(expense);

    if (result.isFailure || result.data == null) {
      state = state.copyWith(isSubmitting: false, errorMessage: result.error);
      return result;
    }

    state = state.copyWith(isSubmitting: false, errorMessage: null);
    return result;
  }

  Future<Result<void>> deleteExpense(String expenseId) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final result = await ExpenseRepository.deleteExpense(expenseId);

    if (result.isFailure) {
      state = state.copyWith(isSubmitting: false, errorMessage: result.error);
      return result;
    }

    state = state.copyWith(isSubmitting: false, errorMessage: null);
    return result;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

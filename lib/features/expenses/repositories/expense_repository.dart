import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/result.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

class ExpenseDashboardSummary {
  final double todayTotal;
  final double weekTotal;
  final double monthTotal;
  final double total;
  final Map<ExpenseCategory, double> categoryTotals;

  const ExpenseDashboardSummary({
    required this.todayTotal,
    required this.weekTotal,
    required this.monthTotal,
    required this.total,
    required this.categoryTotals,
  });
}

class ExpenseRepository {
  ExpenseRepository._();

  static Stream<List<ExpenseModel>> getExpenses() {
    return ExpenseService.watchExpenses();
  }

  static Future<Result<ExpenseModel>> getExpense(String expenseId) async {
    try {
      final expense = await ExpenseService.getExpense(expenseId);

      if (expense == null) {
        return Result.failure('Expense not found.');
      }

      return Result.success(expense);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to fetch expense.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<List<ExpenseModel>>> getExpensesByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final expenses = await ExpenseService.getExpensesByDateRange(
        start: start,
        end: end,
      );

      return Result.success(expenses);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to fetch expenses.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<ExpenseModel>> createExpense(
    ExpenseModel expense,
  ) async {
    try {
      final savedExpense = await ExpenseService.createExpense(expense);
      return Result.success(savedExpense);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to create expense.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<ExpenseModel>> updateExpense(
    ExpenseModel expense,
  ) async {
    try {
      final savedExpense = await ExpenseService.updateExpense(expense);
      return Result.success(savedExpense);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to update expense.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> deleteExpense(String expenseId) async {
    try {
      await ExpenseService.deleteExpense(expenseId);
      return Result.success();
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Failed to delete expense.');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static List<ExpenseModel> filterExpenses(
    List<ExpenseModel> expenses, {
    String searchQuery = '',
    ExpenseCategory? category,
    DateTimeRange? dateRange,
  }) {
    return expenses.where((expense) {
      final matchesSearch = expense.matchesSearch(searchQuery);
      final matchesCategory = category == null || expense.category == category;
      final matchesDateRange =
          dateRange == null ||
          expense.isWithinRange(dateRange.start, dateRange.end);
      return matchesSearch && matchesCategory && matchesDateRange;
    }).toList();
  }

  static double totalExpenses(List<ExpenseModel> expenses) {
    return expenses.fold<double>(0, (currentTotal, expense) {
      return currentTotal + expense.amount;
    });
  }

  static double totalExpensesForRange(
    List<ExpenseModel> expenses,
    DateTime start,
    DateTime end,
  ) {
    return totalExpenses(
      expenses.where((expense) => expense.isWithinRange(start, end)).toList(),
    );
  }

  static double totalExpensesForDay(List<ExpenseModel> expenses, DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return totalExpensesForRange(expenses, normalized, normalized);
  }

  static double totalExpensesForMonth(
    List<ExpenseModel> expenses,
    DateTime month,
  ) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return totalExpensesForRange(expenses, start, end);
  }

  static Map<ExpenseCategory, double> totalExpensesByCategory(
    List<ExpenseModel> expenses,
  ) {
    final totals = <ExpenseCategory, double>{};

    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  static ExpenseDashboardSummary summarizeExpenses(
    List<ExpenseModel> expenses, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(current.year, current.month, 1);

    return ExpenseDashboardSummary(
      todayTotal: totalExpensesForDay(expenses, today),
      weekTotal: totalExpensesForRange(expenses, startOfWeek, today),
      monthTotal: totalExpensesForRange(expenses, startOfMonth, today),
      total: totalExpenses(expenses),
      categoryTotals: totalExpensesByCategory(expenses),
    );
  }
}

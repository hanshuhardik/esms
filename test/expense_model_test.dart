import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:electrical_shop/features/expenses/models/expense_model.dart';
import 'package:electrical_shop/features/expenses/repositories/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ExpenseModel buildExpense({
  required String id,
  required String title,
  required double amount,
  required ExpenseCategory category,
  required ExpensePaymentMethod paymentMethod,
  required DateTime date,
  String? description,
}) {
  return ExpenseModel(
    id: id,
    title: title,
    description: description,
    amount: amount,
    category: category,
    paymentMethod: paymentMethod,
    expenseDate: date,
    createdBy: 'Admin',
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('ExpenseModel', () {
    test('serializes and deserializes safely', () {
      final expense = buildExpense(
        id: 'e1',
        title: 'Electricity bill',
        amount: 1250.75,
        category: ExpenseCategory.electricity,
        paymentMethod: ExpensePaymentMethod.bankTransfer,
        date: DateTime(2026, 8, 1, 10),
        description: 'August power bill',
      );

      final decoded = ExpenseModel.fromMap({
        ...expense.toMap(),
        'createdAt': Timestamp.fromDate(expense.createdAt),
        'updatedAt': Timestamp.fromDate(expense.updatedAt),
        'expenseDate': Timestamp.fromDate(expense.expenseDate),
      }, documentId: expense.id);

      expect(decoded.id, expense.id);
      expect(decoded.title, expense.title);
      expect(decoded.amount, expense.amount);
      expect(decoded.category, expense.category);
      expect(decoded.paymentMethod, expense.paymentMethod);
      expect(decoded.description, expense.description);
    });

    test('validates amount, title, date, category and payment method', () {
      expect(ExpenseModel.validateTitle(''), isNotNull);
      expect(ExpenseModel.validateTitle('Stationery'), isNull);
      expect(ExpenseModel.validateAmount(0), isNotNull);
      expect(ExpenseModel.validateAmount(15.5), isNull);
      expect(ExpenseModel.validateCategory(null), isNotNull);
      expect(ExpenseModel.validatePaymentMethod(null), isNotNull);
      expect(ExpenseModel.validateDate(null), isNotNull);
    });

    test('normalizes category and payment method labels', () {
      final expense = buildExpense(
        id: 'e2',
        title: 'Rent',
        amount: 10000,
        category: ExpenseCategory.rent,
        paymentMethod: ExpensePaymentMethod.cash,
        date: DateTime(2026, 8, 2),
      );

      expect(expense.searchText, contains('rent'));
      expect(expense.searchText, contains('cash'));
      expect(expense.matchesSearch('RENT'), isTrue);
      expect(
        expense.isWithinRange(DateTime(2026, 8, 1), DateTime(2026, 8, 3)),
        isTrue,
      );
    });
  });

  group('ExpenseRepository helpers', () {
    final expenses = [
      buildExpense(
        id: 'e1',
        title: 'Electricity',
        amount: 1200,
        category: ExpenseCategory.electricity,
        paymentMethod: ExpensePaymentMethod.bankTransfer,
        date: DateTime(2026, 8, 1),
      ),
      buildExpense(
        id: 'e2',
        title: 'Fuel',
        amount: 500,
        category: ExpenseCategory.transport,
        paymentMethod: ExpensePaymentMethod.cash,
        date: DateTime(2026, 8, 2),
      ),
      buildExpense(
        id: 'e3',
        title: 'Cleaning',
        amount: 250,
        category: ExpenseCategory.miscellaneous,
        paymentMethod: ExpensePaymentMethod.upi,
        date: DateTime(2026, 8, 10),
      ),
    ];

    test('filters by search, category and date range', () {
      final filtered = ExpenseRepository.filterExpenses(
        expenses,
        searchQuery: 'fuel',
        category: ExpenseCategory.transport,
        dateRange: DateTimeRange(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 2),
        ),
      );

      expect(filtered, hasLength(1));
      expect(filtered.single.id, 'e2');
    });

    test('calculates totals by day, month, range and category', () {
      expect(ExpenseRepository.totalExpenses(expenses), 1950);
      expect(
        ExpenseRepository.totalExpensesForDay(expenses, DateTime(2026, 8, 2)),
        500,
      );
      expect(
        ExpenseRepository.totalExpensesForMonth(expenses, DateTime(2026, 8, 1)),
        1950,
      );
      expect(
        ExpenseRepository.totalExpensesForRange(
          expenses,
          DateTime(2026, 8, 1),
          DateTime(2026, 8, 5),
        ),
        1700,
      );

      final byCategory = ExpenseRepository.totalExpensesByCategory(expenses);
      expect(byCategory[ExpenseCategory.electricity], 1200);
      expect(byCategory[ExpenseCategory.transport], 500);
      expect(byCategory[ExpenseCategory.miscellaneous], 250);
    });

    test('summarizes dashboard totals', () {
      final summary = ExpenseRepository.summarizeExpenses(
        expenses,
        now: DateTime(2026, 8, 10),
      );

      expect(summary.total, 1950);
      expect(summary.monthTotal, 1950);
      expect(summary.todayTotal, 250);
      expect(summary.weekTotal, 250);
      expect(summary.categoryTotals[ExpenseCategory.electricity], 1200);
    });
  });
}

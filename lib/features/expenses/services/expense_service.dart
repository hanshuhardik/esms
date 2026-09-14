import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../shared/models/activity_log_model.dart';
import '../models/expense_model.dart';

class ExpenseService {
  ExpenseService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _expenses =>
      _firestore.collection(FirestoreCollections.expenses);

  static CollectionReference<Map<String, dynamic>> get _activityLogs =>
      _firestore.collection(FirestoreCollections.activityLogs);

  static Stream<List<ExpenseModel>> watchExpenses() {
    return _expenses
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ExpenseModel.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(),
        );
  }

  static Future<ExpenseModel?> getExpense(String expenseId) async {
    final doc = await _expenses.doc(expenseId).get();

    if (!doc.exists) {
      return null;
    }

    return ExpenseModel.fromMap(doc.data()!, documentId: doc.id);
  }

  static Future<List<ExpenseModel>> getExpensesByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day + 1);

    final snapshot = await _expenses
        .where(
          'expenseDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedStart),
        )
        .where('expenseDate', isLessThan: Timestamp.fromDate(normalizedEnd))
        .orderBy('expenseDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), documentId: doc.id))
        .toList();
  }

  static Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final expenseRef = _expenses.doc(expense.id);
    final user = AuthService.currentUser;
    final createdBy = expense.createdBy.trim().isNotEmpty == true
        ? expense.createdBy.trim()
        : (user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!.trim()
              : (user?.email ?? 'Unknown Staff'));
    final now = DateTime.now();

    return _firestore.runTransaction((transaction) async {
      final existingSnapshot = await transaction.get(expenseRef);
      if (existingSnapshot.exists) {
        return ExpenseModel.fromMap(
          existingSnapshot.data()!,
          documentId: existingSnapshot.id,
        );
      }

      final normalizedExpense = expense.copyWith(
        createdBy: createdBy,
        updatedAt: now,
      );

      transaction.set(expenseRef, normalizedExpense.toMap());
      final logRef = _activityLogs.doc(const Uuid().v4());
      transaction.set(
        logRef,
        _buildExpenseLog(
          logId: logRef.id,
          expense: normalizedExpense,
          action: 'created',
          staffId: user?.uid ?? 'unknown',
          staffName: createdBy,
          now: now,
          notes: _expenseLogNotes(normalizedExpense),
        ),
      );

      return normalizedExpense;
    });
  }

  static Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final expenseRef = _expenses.doc(expense.id);
    final user = AuthService.currentUser;
    final now = DateTime.now();

    return _firestore.runTransaction((transaction) async {
      final existingSnapshot = await transaction.get(expenseRef);
      if (!existingSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Expense not found.',
        );
      }

      final currentExpense = ExpenseModel.fromMap(
        existingSnapshot.data()!,
        documentId: existingSnapshot.id,
      );
      final normalizedExpense = expense.copyWith(
        createdBy: currentExpense.createdBy,
        createdAt: currentExpense.createdAt,
        updatedAt: now,
      );

      transaction.update(expenseRef, normalizedExpense.toMap());
      final logRef = _activityLogs.doc(const Uuid().v4());
      transaction.set(
        logRef,
        _buildExpenseLog(
          logId: logRef.id,
          expense: normalizedExpense,
          action: 'updated',
          staffId: user?.uid ?? 'unknown',
          staffName: _resolveStaffName(user, currentExpense.createdBy),
          now: now,
          notes: _expenseLogNotes(normalizedExpense),
        ),
      );

      return normalizedExpense;
    });
  }

  static Future<void> deleteExpense(String expenseId) async {
    final expenseRef = _expenses.doc(expenseId);
    final user = AuthService.currentUser;
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(expenseRef);
      if (!snapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Expense not found.',
        );
      }

      final expense = ExpenseModel.fromMap(
        snapshot.data()!,
        documentId: snapshot.id,
      );
      transaction.delete(expenseRef);
      final logRef = _activityLogs.doc(const Uuid().v4());
      transaction.set(
        logRef,
        _buildExpenseLog(
          logId: logRef.id,
          expense: expense,
          action: 'deleted',
          staffId: user?.uid ?? 'unknown',
          staffName: _resolveStaffName(user, expense.createdBy),
          now: now,
          notes: _expenseLogNotes(expense),
        ),
      );
    });
  }

  static Map<String, dynamic> _buildExpenseLog({
    required String logId,
    required ExpenseModel expense,
    required String action,
    required String staffId,
    required String staffName,
    required DateTime now,
    String? notes,
  }) {
    return ActivityLogModel(
      id: logId,
      category: 'expense',
      action: action,
      productId: expense.id,
      productName: expense.title,
      previousStock: 0,
      newStock: 0,
      difference: 0,
      reason: 'Expense $action',
      notes: notes,
      staffId: staffId,
      staffName: staffName,
      createdAt: now,
    ).toMap();
  }

  static String _resolveStaffName(dynamic user, String fallback) {
    if (user?.displayName?.trim().isNotEmpty == true) {
      return user.displayName!.trim();
    }

    if (user?.email != null && user.email.toString().trim().isNotEmpty) {
      return user.email.toString().trim();
    }

    return fallback.isNotEmpty ? fallback : 'Unknown Staff';
  }

  static String _expenseLogNotes(ExpenseModel expense) {
    return '${expense.category.label} • ${expense.paymentMethod.label} • ${expense.amount}';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseCategory {
  electricity('Electricity'),
  rent('Rent'),
  salary('Salary'),
  transport('Transport'),
  maintenance('Maintenance'),
  office('Office'),
  miscellaneous('Miscellaneous');

  const ExpenseCategory(this.label);

  final String label;
}

enum ExpensePaymentMethod {
  cash('Cash'),
  upi('UPI'),
  card('Card'),
  bankTransfer('Bank Transfer'),
  other('Other');

  const ExpensePaymentMethod(this.label);

  final String label;
}

class ExpenseModel {
  static const Object _unset = Object();

  final String id;
  final String title;
  final String? description;
  final double amount;
  final ExpenseCategory category;
  final ExpensePaymentMethod paymentMethod;
  final DateTime expenseDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.expenseDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return ExpenseModel(
      id: _readString(map['id'], fallback: documentId ?? ''),
      title: _readString(map['title']),
      description: _readOptionalString(map['description']),
      amount: _readDouble(map['amount']),
      category: _readExpenseCategory(map['category']),
      paymentMethod: _readPaymentMethod(map['paymentMethod']),
      expenseDate:
          _readDate(map['expenseDate']) ??
          _readDate(map['createdAt']) ??
          DateTime.now(),
      createdBy: _readString(map['createdBy']),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category.name,
      'paymentMethod': paymentMethod.name,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    Object? description = _unset,
    double? amount,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
    DateTime? expenseDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description == _unset
          ? this.description
          : description as String?,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseDate: expenseDate ?? this.expenseDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get searchText {
    final descriptionText = description ?? '';
    return '$title $descriptionText ${category.label} ${paymentMethod.label} $createdBy'
        .toLowerCase();
  }

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return searchText.contains(normalized);
  }

  bool isWithinRange(DateTime start, DateTime end) {
    final date = DateTime(expenseDate.year, expenseDate.month, expenseDate.day);
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return !date.isBefore(normalizedStart) && !date.isAfter(normalizedEnd);
  }

  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required.';
    }

    return null;
  }

  static String? validateAmount(double? value) {
    if (value == null || value <= 0) {
      return 'Amount must be greater than zero.';
    }

    return null;
  }

  static String? validateCategory(ExpenseCategory? category) {
    if (category == null) {
      return 'Category is required.';
    }

    return null;
  }

  static String? validatePaymentMethod(ExpensePaymentMethod? method) {
    if (method == null) {
      return 'Payment method is required.';
    }

    return null;
  }

  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'Expense date is required.';
    }

    return null;
  }

  static ExpenseCategory _readExpenseCategory(dynamic value) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.name == value || category.label == value,
      orElse: () => ExpenseCategory.miscellaneous,
    );
  }

  static ExpensePaymentMethod _readPaymentMethod(dynamic value) {
    return ExpensePaymentMethod.values.firstWhere(
      (method) => method.name == value || method.label == value,
      orElse: () => ExpensePaymentMethod.cash,
    );
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _readOptionalString(dynamic value) {
    final text = _readString(value);
    return text.isEmpty ? null : text;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}

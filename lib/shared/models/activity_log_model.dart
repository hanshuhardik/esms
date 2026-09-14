import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String category;
  final String action;
  final String productId;
  final String productName;
  final int previousStock;
  final int newStock;
  final int difference;
  final String reason;
  final String? notes;
  final String staffId;
  final String staffName;
  final DateTime createdAt;

  const ActivityLogModel({
    required this.id,
    required this.category,
    required this.action,
    required this.productId,
    required this.productName,
    required this.previousStock,
    required this.newStock,
    required this.difference,
    required this.reason,
    required this.notes,
    required this.staffId,
    required this.staffName,
    required this.createdAt,
  });

  factory ActivityLogModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return ActivityLogModel(
      id: _readString(map['id'], fallback: documentId ?? ''),
      category: _readString(map['category'], fallback: 'inventory'),
      action: _readString(map['action']),
      productId: _readString(map['productId']),
      productName: _readString(map['productName']),
      previousStock: _readInt(map['previousStock']),
      newStock: _readInt(map['newStock']),
      difference: _readInt(map['difference']),
      reason: _readString(map['reason']),
      notes: _readOptionalString(map['notes']),
      staffId: _readString(map['staffId']),
      staffName: _readString(map['staffName'], fallback: 'Unknown Staff'),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'action': action,
      'productId': productId,
      'productName': productName,
      'previousStock': previousStock,
      'newStock': newStock,
      'difference': difference,
      'reason': reason,
      'notes': notes,
      'staffId': staffId,
      'staffName': staffName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
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

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
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

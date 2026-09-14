import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnItem {
  final String originalBillId;
  final int originalItemIndex;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;

  const ReturnItem({
    required this.originalBillId,
    required this.originalItemIndex,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      originalBillId: _readString(map['originalBillId']),
      originalItemIndex: _readInt(map['originalItemIndex']),
      productId: _readString(map['productId']),
      productName: _readString(map['productName']),
      quantity: _readInt(map['quantity']),
      unitPrice: _readDouble(map['unitPrice']),
      total: _readDouble(map['total']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'originalBillId': originalBillId,
      'originalItemIndex': originalItemIndex,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  ReturnItem copyWith({
    String? originalBillId,
    int? originalItemIndex,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return ReturnItem(
      originalBillId: originalBillId ?? this.originalBillId,
      originalItemIndex: originalItemIndex ?? this.originalItemIndex,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }

  static String _readString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text;
  }

  static int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

class ReturnModel {
  final String returnId;
  final List<String> originalBillIds;
  final String customerPhone;
  final String? customerName;
  final List<ReturnItem> items;
  final double subtotal;
  final double discount;
  final double refundAmount;
  final double amountAppliedToDue;
  final double cashRefundAmount;
  final DateTime createdAt;
  final String createdBy;

  /// Amount of each source bill discount consumed by this return.
  /// This keeps bill-level discount accounting auditable without allocating
  /// discounts to individual products.
  final Map<String, double> discountAllocations;

  const ReturnModel({
    required this.returnId,
    required this.originalBillIds,
    required this.customerPhone,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.refundAmount,
    this.amountAppliedToDue = 0,
    this.cashRefundAmount = 0,
    required this.createdAt,
    required this.createdBy,
    this.discountAllocations = const {},
  });

  factory ReturnModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawBillIds = map['originalBillIds'];
    final rawItems = map['items'];
    final rawAllocations = map['discountAllocations'];
    final allocations = <String, double>{};

    if (rawAllocations is Map) {
      rawAllocations.forEach((key, value) {
        allocations[key.toString()] = _readDouble(value);
      });
    }

    return ReturnModel(
      returnId: _readString(map['returnId'], fallback: documentId ?? ''),
      originalBillIds: rawBillIds is List
          ? rawBillIds.map((value) => value.toString()).toList()
          : const [],
      customerPhone: _readString(map['customerPhone']),
      customerName: _readOptionalString(map['customerName']),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => ReturnItem.fromMap(item.cast<String, dynamic>()))
                .toList()
          : const [],
      subtotal: _readDouble(map['subtotal']),
      discount: _readDouble(map['discount']),
      refundAmount: _readDouble(map['refundAmount']),
      amountAppliedToDue: _readDouble(map['amountAppliedToDue']),
      cashRefundAmount: _readDouble(map['cashRefundAmount']),
      createdAt:
          _readDate(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      createdBy: _readString(map['createdBy']),
      discountAllocations: allocations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'returnId': returnId,
      'originalBillIds': originalBillIds,
      'customerPhone': customerPhone,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'refundAmount': refundAmount,
      'amountAppliedToDue': amountAppliedToDue,
      'cashRefundAmount': cashRefundAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'discountAllocations': discountAllocations,
    };
  }

  ReturnModel copyWith({
    String? returnId,
    List<String>? originalBillIds,
    String? customerPhone,
    Object? customerName = _unset,
    List<ReturnItem>? items,
    double? subtotal,
    double? discount,
    double? refundAmount,
    double? amountAppliedToDue,
    double? cashRefundAmount,
    DateTime? createdAt,
    String? createdBy,
    Map<String, double>? discountAllocations,
  }) {
    return ReturnModel(
      returnId: returnId ?? this.returnId,
      originalBillIds: originalBillIds ?? this.originalBillIds,
      customerPhone: customerPhone ?? this.customerPhone,
      customerName: customerName == _unset
          ? this.customerName
          : customerName as String?,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      refundAmount: refundAmount ?? this.refundAmount,
      amountAppliedToDue: amountAppliedToDue ?? this.amountAppliedToDue,
      cashRefundAmount: cashRefundAmount ?? this.cashRefundAmount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      discountAllocations: discountAllocations ?? this.discountAllocations,
    );
  }

  static const Object _unset = Object();

  static String _readString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _readOptionalString(dynamic value) {
    final text = _readString(value);
    return text.isEmpty ? null : text;
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

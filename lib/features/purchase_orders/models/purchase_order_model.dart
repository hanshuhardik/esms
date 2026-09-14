import 'package:cloud_firestore/cloud_firestore.dart';

enum PurchaseOrderStatus {
  draft('Draft'),
  ordered('Ordered'),
  partiallyReceived('Partially Received'),
  completed('Completed'),
  cancelled('Cancelled');

  const PurchaseOrderStatus(this.label);

  final String label;

  bool get isSystemManaged =>
      this == PurchaseOrderStatus.partiallyReceived ||
      this == PurchaseOrderStatus.completed;
}

class PurchaseOrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final int quantityOrdered;
  final int quantityReceived;
  final double unitCost;
  final double gstPercent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseOrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitCost,
    required this.gstPercent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PurchaseOrderItemModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return PurchaseOrderItemModel(
      id: _readString(map['id'], fallback: documentId ?? ''),
      productId: _readString(map['productId']),
      productName: _readString(map['productName']),
      sku: _readString(map['sku']),
      quantityOrdered: _readInt(map['quantityOrdered']),
      quantityReceived: _readInt(map['quantityReceived']),
      unitCost: _readDouble(map['unitCost']),
      gstPercent: _readDouble(map['gstPercent']),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantityOrdered': quantityOrdered,
      'quantityReceived': quantityReceived,
      'unitCost': unitCost,
      'gstPercent': gstPercent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PurchaseOrderItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? sku,
    int? quantityOrdered,
    int? quantityReceived,
    double? unitCost,
    double? gstPercent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrderItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantityOrdered: quantityOrdered ?? this.quantityOrdered,
      quantityReceived: quantityReceived ?? this.quantityReceived,
      unitCost: unitCost ?? this.unitCost,
      gstPercent: gstPercent ?? this.gstPercent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get remainingQuantity => quantityOrdered - quantityReceived < 0
      ? 0
      : quantityOrdered - quantityReceived;

  double get lineSubtotal => quantityOrdered * unitCost;

  double get lineGstAmount => lineSubtotal * gstPercent / 100;

  double get lineTotal => lineSubtotal + lineGstAmount;

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
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

class PurchaseOrderModel {
  static const Object _unset = Object();

  final String id;
  final String orderNumber;
  final String supplierId;
  final String supplierName;
  final PurchaseOrderStatus status;
  final List<PurchaseOrderItemModel> items;
  final String? notes;
  final double subtotal;
  final double gstAmount;
  final double grandTotal;
  final String createdById;
  final String createdByName;
  final String? receivedById;
  final String? receivedByName;
  final DateTime? receivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseOrderModel({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.items,
    required this.notes,
    required this.subtotal,
    required this.gstAmount,
    required this.grandTotal,
    required this.createdById,
    required this.createdByName,
    required this.receivedById,
    required this.receivedByName,
    required this.receivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PurchaseOrderModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final rawItems = map['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => PurchaseOrderItemModel.fromMap(
                  item.cast<String, dynamic>(),
                ),
              )
              .toList()
        : <PurchaseOrderItemModel>[];

    return PurchaseOrderModel(
      id: _readString(map['id'], fallback: documentId ?? ''),
      orderNumber: _readString(map['orderNumber']),
      supplierId: _readString(map['supplierId']),
      supplierName: _readString(map['supplierName']),
      status: PurchaseOrderStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => PurchaseOrderStatus.draft,
      ),
      items: items,
      notes: _readOptionalString(map['notes']),
      subtotal: _readDouble(map['subtotal']),
      gstAmount: _readDouble(map['gstAmount']),
      grandTotal: _readDouble(map['grandTotal']),
      createdById: _readString(map['createdById']),
      createdByName: _readString(map['createdByName']),
      receivedById: _readOptionalString(map['receivedById']),
      receivedByName: _readOptionalString(map['receivedByName']),
      receivedAt: _readDate(map['receivedAt']),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'status': status.name,
      'items': items.map((item) => item.toMap()).toList(),
      'notes': notes,
      'subtotal': subtotal,
      'gstAmount': gstAmount,
      'grandTotal': grandTotal,
      'createdById': createdById,
      'createdByName': createdByName,
      'receivedById': receivedById,
      'receivedByName': receivedByName,
      'receivedAt': receivedAt == null ? null : Timestamp.fromDate(receivedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PurchaseOrderModel copyWith({
    String? id,
    String? orderNumber,
    String? supplierId,
    String? supplierName,
    PurchaseOrderStatus? status,
    List<PurchaseOrderItemModel>? items,
    Object? notes = _unset,
    double? subtotal,
    double? gstAmount,
    double? grandTotal,
    String? createdById,
    String? createdByName,
    Object? receivedById = _unset,
    Object? receivedByName = _unset,
    Object? receivedAt = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      status: status ?? this.status,
      items: items ?? this.items,
      notes: notes == _unset ? this.notes : notes as String?,
      subtotal: subtotal ?? this.subtotal,
      gstAmount: gstAmount ?? this.gstAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      receivedById: receivedById == _unset
          ? this.receivedById
          : receivedById as String?,
      receivedByName: receivedByName == _unset
          ? this.receivedByName
          : receivedByName as String?,
      receivedAt: receivedAt == _unset
          ? this.receivedAt
          : receivedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get totalOrderedQuantity =>
      items.fold(0, (total, item) => total + item.quantityOrdered);

  int get totalReceivedQuantity =>
      items.fold(0, (total, item) => total + item.quantityReceived);

  int get totalRemainingQuantity =>
      items.fold(0, (total, item) => total + item.remainingQuantity);

  bool get isCompleted => status == PurchaseOrderStatus.completed;

  bool get isCancelable =>
      status == PurchaseOrderStatus.draft ||
      status == PurchaseOrderStatus.ordered;

  bool get canReceive =>
      status != PurchaseOrderStatus.cancelled &&
      status != PurchaseOrderStatus.completed;

  static int clampReceivedQuantity({
    required int requestedQuantity,
    required int remainingQuantity,
  }) {
    return requestedQuantity.clamp(0, remainingQuantity).toInt();
  }

  static PurchaseOrderStatus resolveStatusAfterReceive({
    required PurchaseOrderStatus currentStatus,
    required bool anyReceived,
    required bool allCompleted,
  }) {
    if (currentStatus == PurchaseOrderStatus.cancelled ||
        currentStatus == PurchaseOrderStatus.completed) {
      return currentStatus;
    }

    if (allCompleted) {
      return PurchaseOrderStatus.completed;
    }

    if (anyReceived) {
      return PurchaseOrderStatus.partiallyReceived;
    }

    return currentStatus;
  }

  String get searchText {
    final itemText = items.map((item) => item.productName).join(' ');
    return '$orderNumber $supplierName $itemText'.toLowerCase();
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

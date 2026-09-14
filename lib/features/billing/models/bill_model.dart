import 'package:cloud_firestore/cloud_firestore.dart';

enum BillStatus {
  draft('Draft'),
  completed('Completed'),
  cancelled('Cancelled');

  const BillStatus(this.label);

  final String label;

  bool get isFinalized => this == BillStatus.completed;
}

enum BillPaymentMethod {
  cash('Cash'),
  upi('UPI'),
  card('Card'),
  other('Other');

  const BillPaymentMethod(this.label);

  final String label;
}

enum BillPaymentStatus {
  paid('Paid'),
  partial('Partial'),
  due('Due');

  const BillPaymentStatus(this.label);

  final String label;
}

enum BillListFilter {
  all('All'),
  paid('Paid'),
  due('Due');

  const BillListFilter(this.label);

  final String label;
}

class BillItemModel {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double sellingPrice;
  final double discount;

  const BillItemModel({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.sellingPrice,
    this.discount = 0,
  });

  factory BillItemModel.fromMap(Map<String, dynamic> map) {
    final quantity = _readInt(map['quantity']);
    final sellingPrice = _readDouble(map['sellingPrice']);
    final discount = _readDouble(map['discount']);

    return BillItemModel(
      productId: _readString(map['productId']),
      productName: _readString(map['productName']),
      sku: _readString(map['sku']),
      quantity: quantity,
      sellingPrice: sellingPrice,
      discount: discount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'sellingPrice': sellingPrice,
      'discount': discount,
      'lineTotal': lineTotal,
    };
  }

  BillItemModel copyWith({
    String? productId,
    String? productName,
    String? sku,
    int? quantity,
    double? sellingPrice,
    double? discount,
  }) {
    return BillItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discount: discount ?? this.discount,
    );
  }

  double get lineSubtotal => quantity * sellingPrice;

  double get lineTotal => calculateLineTotal(
    quantity: quantity,
    sellingPrice: sellingPrice,
    discount: discount,
  );

  bool canSellAgainstStock(int availableStock) => quantity <= availableStock;

  static double calculateLineTotal({
    required int quantity,
    required double sellingPrice,
    double discount = 0,
  }) {
    final subtotal = quantity * sellingPrice;
    final safeDiscount = discount < 0 ? 0 : discount;
    final total = subtotal - safeDiscount;

    return total < 0 ? 0 : total;
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class BillModel {
  static const Object _unset = Object();

  final String id;
  final String billNumber;
  final int billSequence;
  final List<BillItemModel> items;
  final double subtotal;
  final double discount;
  final double total;
  final BillPaymentMethod paymentMethod;
  final double amountPaid;
  final double amountDue;
  final BillPaymentStatus paymentStatus;
  final String? customerName;
  final String? customerPhone;
  final String takenBy;
  final String createdBy;
  final DateTime createdAt;
  final BillStatus status;

  const BillModel({
    required this.id,
    required this.billNumber,
    required this.billSequence,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    this.amountPaid = 0,
    this.amountDue = 0,
    this.paymentStatus = BillPaymentStatus.due,
    required this.customerName,
    required this.customerPhone,
    this.takenBy = '',
    required this.createdBy,
    required this.createdAt,
    required this.status,
  });

  factory BillModel.draft({
    required String id,
    required List<BillItemModel> items,
    required double discount,
    required BillPaymentMethod paymentMethod,
    String? customerName,
    String? customerPhone,
    String takenBy = '',
    required String createdBy,
    DateTime? createdAt,
  }) {
    final subtotal = calculateSubtotal(items);
    final total = calculateTotal(subtotal: subtotal, discount: discount);

    return BillModel(
      id: id,
      billNumber: '',
      billSequence: 0,
      items: items,
      subtotal: subtotal,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      amountPaid: total,
      amountDue: 0,
      paymentStatus: BillPaymentStatus.paid,
      customerName: customerName,
      customerPhone: customerPhone,
      takenBy: takenBy,
      createdBy: createdBy,
      createdAt: createdAt ?? DateTime.now(),
      status: BillStatus.draft,
    );
  }

  factory BillModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawItems = map['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => BillItemModel.fromMap(item.cast<String, dynamic>()),
              )
              .toList()
        : <BillItemModel>[];

    final total = _readDouble(map['total']);
    final hasPaymentFields =
        map.containsKey('amountPaid') ||
        map.containsKey('amountDue') ||
        map.containsKey('paymentStatus');
    final amountPaid = hasPaymentFields
        ? _readDouble(map['amountPaid']).clamp(0.0, total).toDouble()
        : total;
    final amountDue = (total - amountPaid).clamp(0.0, total).toDouble();
    final paymentStatus = hasPaymentFields
        ? BillPaymentStatus.values.firstWhere(
            (value) => value.name == map['paymentStatus'],
            orElse: () => _statusForPayment(amountPaid, amountDue, total),
          )
        : BillPaymentStatus.paid;

    return BillModel(
      id: _readString(map['id'], fallback: documentId ?? ''),
      billNumber: _readString(map['billNumber']),
      billSequence: _readInt(map['billSequence']),
      items: items,
      subtotal: _readDouble(map['subtotal']),
      discount: _readDouble(map['discount']),
      total: total,
      paymentMethod: BillPaymentMethod.values.firstWhere(
        (method) => method.name == map['paymentMethod'],
        orElse: () => BillPaymentMethod.cash,
      ),
      amountPaid: amountPaid,
      amountDue: amountDue,
      paymentStatus: paymentStatus,
      customerName: _readOptionalString(map['customerName']),
      customerPhone: _readOptionalString(map['customerPhone']),
      takenBy: _readString(map['takenBy']),
      createdBy: _readString(map['createdBy']),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      status: BillStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => BillStatus.completed,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billNumber': billNumber,
      'billSequence': billSequence,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'amountPaid': amountPaid,
      'amountDue': amountDue,
      'paymentStatus': paymentStatus.name,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'takenBy': takenBy,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  BillModel copyWith({
    String? id,
    String? billNumber,
    int? billSequence,
    List<BillItemModel>? items,
    double? subtotal,
    double? discount,
    double? total,
    BillPaymentMethod? paymentMethod,
    double? amountPaid,
    double? amountDue,
    BillPaymentStatus? paymentStatus,
    Object? customerName = _unset,
    Object? customerPhone = _unset,
    String? takenBy,
    String? createdBy,
    DateTime? createdAt,
    BillStatus? status,
  }) {
    return BillModel(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      billSequence: billSequence ?? this.billSequence,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountPaid: amountPaid ?? this.amountPaid,
      amountDue: amountDue ?? this.amountDue,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      customerName: customerName == _unset
          ? this.customerName
          : customerName as String?,
      customerPhone: customerPhone == _unset
          ? this.customerPhone
          : customerPhone as String?,
      takenBy: takenBy ?? this.takenBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  bool get isCompleted => status == BillStatus.completed;

  bool get isCancelled => status == BillStatus.cancelled;

  bool get isDraft => status == BillStatus.draft;

  bool get hasCustomerPhone => customerPhone?.trim().isNotEmpty == true;

  String get searchText {
    final itemsText = items.map((item) => item.productName).join(' ');
    return '$billNumber $customerName $customerPhone $createdBy $itemsText'
        .toLowerCase();
  }

  static int nextSequence(int currentSequence) => currentSequence + 1;

  static String formatBillNumber(
    String prefix,
    int sequence, {
    int padLength = 6,
  }) {
    final safePrefix = prefix.trim().isEmpty ? 'BILL' : prefix.trim();
    final number = sequence.toString().padLeft(padLength, '0');
    return '$safePrefix-$number';
  }

  static double calculateSubtotal(List<BillItemModel> items) {
    return items.fold<double>(0, (subtotal, item) => subtotal + item.lineTotal);
  }

  static double calculateTotal({
    required double subtotal,
    required double discount,
  }) {
    final safeDiscount = discount < 0 ? 0 : discount;
    final total = subtotal - safeDiscount;
    return total < 0 ? 0 : total;
  }

  static bool canSellAgainstStock({
    required int requestedQuantity,
    required int availableStock,
  }) {
    return requestedQuantity > 0 && requestedQuantity <= availableStock;
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

  static BillPaymentStatus _statusForPayment(
    double amountPaid,
    double amountDue,
    double total,
  ) {
    if (amountPaid <= 0) return BillPaymentStatus.due;
    if (amountDue <= 0 || amountPaid >= total) {
      return BillPaymentStatus.paid;
    }
    return BillPaymentStatus.partial;
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

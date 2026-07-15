import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductUnit {
  piece('Piece'),
  meter('Meter'),
  packet('Packet');

  const ProductUnit(this.label);

  final String label;
}

enum ProductStatus { active, inactive }

class ProductModel {
  final String id;

  /// Optional SKU
  final String sku;

  /// Product Name
  final String name;

  /// Firestore Brand Document ID
  final String brandId;

  /// Firestore Category Document ID
  final String categoryId;

  /// Unit
  final ProductUnit unit;

  /// Purchase Price
  final double purchasePrice;

  /// Selling Price
  final double sellingPrice;

  /// Current Stock
  final int stockQuantity;

  /// Minimum Stock
  final int minimumStock;

  /// Supplier Document ID
  final String supplierId;

  /// Location Document ID
  final String locationId;

  /// Optional Barcode
  final String? barcode;

  /// Optional Product Image
  final String? imageUrl;

  /// Product Status
  final ProductStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.brandId,
    required this.categoryId,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.minimumStock,
    required this.supplierId,
    required this.locationId,
    this.barcode,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return ProductModel(
      id: _readString(map['id'], fallback: documentId ?? ''),
      sku: _readString(map['sku']),
      name: _readString(map['name']),
      brandId: _readString(map['brandId']),
      categoryId: _readString(map['categoryId']),
      unit: ProductUnit.values.firstWhere(
        (e) => e.name == map['unit'],
        orElse: () => ProductUnit.piece,
      ),
      purchasePrice: _readDouble(map['purchasePrice']),
      sellingPrice: _readDouble(map['sellingPrice']),
      stockQuantity: _readInt(map['stockQuantity']),
      minimumStock: _readInt(map['minimumStock']),
      supplierId: _readString(map['supplierId']),
      locationId: _readString(map['locationId']),
      barcode: _readOptionalString(map['barcode']),
      imageUrl: _readOptionalString(map['imageUrl']),
      status: ProductStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProductStatus.active,
      ),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'brandId': brandId,
      'categoryId': categoryId,
      'unit': unit.name,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'minimumStock': minimumStock,
      'supplierId': supplierId,
      'locationId': locationId,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProductModel copyWith({
    String? id,
    String? sku,
    String? name,
    String? brandId,
    String? categoryId,
    ProductUnit? unit,
    double? purchasePrice,
    double? sellingPrice,
    int? stockQuantity,
    int? minimumStock,
    String? supplierId,
    String? locationId,
    String? barcode,
    String? imageUrl,
    ProductStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      brandId: brandId ?? this.brandId,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStock: minimumStock ?? this.minimumStock,
      supplierId: supplierId ?? this.supplierId,
      locationId: locationId ?? this.locationId,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get profitAmount => sellingPrice - purchasePrice;

  double get profitPercentage {
    if (purchasePrice <= 0) {
      return 0;
    }

    return (profitAmount / purchasePrice) * 100;
  }

  bool get isOutOfStock => stockQuantity <= 0;

  bool get isLowStock => stockQuantity > 0 && stockQuantity <= minimumStock;

  bool get isInStock => !isOutOfStock && !isLowStock;

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

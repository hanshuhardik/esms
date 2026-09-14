import 'package:cloud_firestore/cloud_firestore.dart';

class ShopModel {
  final String id;
  final String shopName;
  final String ownerName;
  final String phone;
  final String email;
  final String address;

  final bool gstEnabled;

  final String currency;

  final String billPrefix;
  final String purchaseOrderPrefix;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopModel({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.gstEnabled,
    required this.currency,
    required this.billPrefix,
    required this.purchaseOrderPrefix,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopModel.fromMap(Map<String, dynamic> map) {
    return ShopModel(
      id: _readString(map['id']),
      shopName: _readString(map['shopName']),
      ownerName: _readString(map['ownerName']),
      phone: _readString(map['phone']),
      email: _readString(map['email']),
      address: _readString(map['address']),
      gstEnabled: map['gstEnabled'] == true,
      currency: _readString(map['currency'], fallback: 'INR'),
      billPrefix: _readString(map['billPrefix'], fallback: 'BILL'),
      purchaseOrderPrefix: _readString(
        map['purchaseOrderPrefix'],
        fallback: 'PO',
      ),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  ShopModel copyWith({
    String? shopName,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    bool? gstEnabled,
    String? currency,
    String? billPrefix,
    String? purchaseOrderPrefix,
    DateTime? updatedAt,
  }) {
    return ShopModel(
      id: id,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstEnabled: gstEnabled ?? this.gstEnabled,
      currency: currency ?? this.currency,
      billPrefix: billPrefix ?? this.billPrefix,
      purchaseOrderPrefix: purchaseOrderPrefix ?? this.purchaseOrderPrefix,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    return value is String ? value : fallback;
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopName': shopName,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'gstEnabled': gstEnabled,
      'currency': currency,
      'billPrefix': billPrefix,
      'purchaseOrderPrefix': purchaseOrderPrefix,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

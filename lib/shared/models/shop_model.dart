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
      id: map['id'] ?? '',
      shopName: map['shopName'] ?? '',
      ownerName: map['ownerName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      gstEnabled: map['gstEnabled'] ?? false,
      currency: map['currency'] ?? 'INR',
      billPrefix: map['billPrefix'] ?? 'BILL',
      purchaseOrderPrefix: map['purchaseOrderPrefix'] ?? 'PO',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
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

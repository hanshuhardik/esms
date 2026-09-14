import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String gstNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierModel({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.gstNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return SupplierModel(
      id: _readString(map['id'], fallback: documentId ?? ''),
      name: _readString(map['name']),
      contactPerson: _readString(map['contactPerson']),
      phone: _readString(map['phone']),
      email: _readString(map['email']),
      address: _readString(map['address']),
      gstNumber: _readString(map['gstNumber']),
      isActive: map['isActive'] ?? true,
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
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

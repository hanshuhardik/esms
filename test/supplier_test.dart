import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electrical_shop/features/staff/models/authorization.dart';
import 'package:electrical_shop/features/staff/models/permission.dart';
import 'package:electrical_shop/features/suppliers/models/supplier_model.dart';
import 'package:electrical_shop/features/suppliers/models/supplier_validator.dart';
import 'package:electrical_shop/features/suppliers/repositories/supplier_repository.dart';
import 'package:electrical_shop/shared/models/user_model.dart';

SupplierModel _supplier({
  String id = 'supplier-1',
  String name = 'Electrical Wholesale',
  bool active = true,
}) {
  final date = DateTime(2026, 9, 4);
  return SupplierModel(
    id: id,
    name: name,
    contactPerson: 'Asha',
    phone: '+911234567890',
    email: 'sales@example.com',
    address: 'Market Road',
    gstNumber: 'GSTIN123',
    isActive: active,
    createdAt: date,
    updatedAt: date,
  );
}

UserModel _user({UserRole role = UserRole.owner, bool active = true}) {
  final date = DateTime(2026, 9, 4);
  return UserModel(
    uid: 'user-1',
    name: 'Owner',
    email: 'owner@example.com',
    phone: '1234567890',
    role: role,
    isActive: active,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('Supplier serialization', () {
    test('round trips supported fields', () {
      final original = _supplier();
      final decoded = SupplierModel.fromMap(original.toMap());

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.contactPerson, original.contactPerson);
      expect(decoded.phone, original.phone);
      expect(decoded.email, original.email);
      expect(decoded.gstNumber, original.gstNumber);
      expect(decoded.isActive, true);
    });

    test('uses document ID and safe defaults', () {
      final date = DateTime(2026, 9, 4);
      final decoded = SupplierModel.fromMap({
        'createdAt': Timestamp.fromDate(date),
        'updatedAt': Timestamp.fromDate(date),
      }, documentId: 'doc-1');

      expect(decoded.id, 'doc-1');
      expect(decoded.isActive, true);
      expect(decoded.createdAt, date);
    });
  });

  group('Supplier validation', () {
    test('validates required name and phone', () {
      expect(SupplierValidator.validateName(' '), isNotNull);
      expect(SupplierValidator.validatePhone('abc'), isNotNull);
      expect(SupplierValidator.validateName('Supplier'), isNull);
      expect(SupplierValidator.validatePhone('+911234567890'), isNull);
    });

    test('allows an empty optional email and validates supplied email', () {
      expect(SupplierValidator.validateEmail(''), isNull);
      expect(SupplierValidator.validateEmail('invalid'), isNotNull);
      expect(SupplierValidator.validateEmail('sales@example.com'), isNull);
    });
  });

  group('Supplier filtering', () {
    final suppliers = [
      _supplier(name: 'Alpha Cables'),
      _supplier(id: 'supplier-2', name: 'Beta Switches', active: false),
    ];

    test('searches supplier fields case-insensitively', () {
      final result = SupplierRepository.filterSuppliers(
        suppliers,
        searchQuery: 'switches',
      );
      expect(result.map((item) => item.id), ['supplier-2']);
    });

    test('filters by active status', () {
      expect(
        SupplierRepository.filterSuppliers(suppliers, active: true),
        hasLength(1),
      );
      expect(
        SupplierRepository.filterSuppliers(suppliers, active: false),
        hasLength(1),
      );
    });
  });

  group('Supplier permissions', () {
    test('active owner and staff can manage suppliers', () {
      expect(Authorization.can(_user(), Permission.manageSuppliers), true);
      expect(
        Authorization.can(
          _user(role: UserRole.staff),
          Permission.manageSuppliers,
        ),
        true,
      );
    });

    test('inactive users and electricians cannot manage suppliers', () {
      expect(
        Authorization.can(_user(active: false), Permission.manageSuppliers),
        false,
      );
      expect(
        Authorization.can(
          _user(role: UserRole.electrician),
          Permission.manageSuppliers,
        ),
        false,
      );
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electrical_shop/features/settings/models/settings_validator.dart';
import 'package:electrical_shop/features/settings/providers/settings_provider.dart';
import 'package:electrical_shop/features/staff/models/authorization.dart';
import 'package:electrical_shop/features/staff/models/permission.dart';
import 'package:electrical_shop/shared/models/shop_model.dart';
import 'package:electrical_shop/shared/models/user_model.dart';

ShopModel _shop() {
  final date = DateTime(2026, 9, 3);
  return ShopModel(
    id: 'default',
    shopName: 'ESMS Electricals',
    ownerName: 'Owner',
    phone: '+911234567890',
    email: 'shop@example.com',
    address: 'Main Road',
    gstEnabled: true,
    currency: 'INR',
    billPrefix: 'BILL',
    purchaseOrderPrefix: 'PO',
    createdAt: date,
    updatedAt: date,
  );
}

UserModel _user({UserRole role = UserRole.owner, bool active = true}) {
  final date = DateTime(2026, 9, 3);
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
  group('ShopModel settings serialization', () {
    test('round trips supported settings fields', () {
      final original = _shop();
      final decoded = ShopModel.fromMap(original.toMap());

      expect(decoded.id, original.id);
      expect(decoded.shopName, original.shopName);
      expect(decoded.phone, original.phone);
      expect(decoded.email, original.email);
      expect(decoded.address, original.address);
      expect(decoded.gstEnabled, true);
      expect(decoded.currency, 'INR');
      expect(decoded.billPrefix, 'BILL');
      expect(decoded.purchaseOrderPrefix, 'PO');
    });

    test('uses safe defaults for missing Firestore values', () {
      final decoded = ShopModel.fromMap(<String, dynamic>{});

      expect(decoded.currency, 'INR');
      expect(decoded.billPrefix, 'BILL');
      expect(decoded.purchaseOrderPrefix, 'PO');
      expect(decoded.gstEnabled, false);
      expect(decoded.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('accepts Firestore timestamps', () {
      final date = DateTime(2026, 9, 3);
      final decoded = ShopModel.fromMap({
        'createdAt': Timestamp.fromDate(date),
        'updatedAt': Timestamp.fromDate(date),
      });

      expect(decoded.createdAt, date);
      expect(decoded.updatedAt, date);
    });
  });

  group('Settings validation', () {
    test('accepts a valid shop', () {
      expect(SettingsValidator.validateShop(_shop()), isNull);
    });

    test('requires shop name', () {
      expect(SettingsValidator.validateShopName(' '), 'Shop name is required');
    });

    test('validates email and phone', () {
      expect(SettingsValidator.validateEmail('invalid'), isNotNull);
      expect(SettingsValidator.validatePhone('abc'), isNotNull);
    });

    test('validates invoice prefixes', () {
      expect(
        SettingsValidator.validatePrefix('BILL-2026', 'Bill prefix'),
        isNull,
      );
      expect(
        SettingsValidator.validatePrefix('BILL 2026', 'Bill prefix'),
        isNotNull,
      );
    });
  });

  group('Settings authorization and state', () {
    test('only an active owner can manage settings', () {
      expect(Authorization.can(_user(), Permission.manageSettings), true);
      expect(
        Authorization.can(
          _user(role: UserRole.staff),
          Permission.manageSettings,
        ),
        false,
      );
      expect(
        Authorization.can(_user(active: false), Permission.manageSettings),
        false,
      );
    });

    test('settings state transitions from loading to loaded', () {
      const loading = SettingsState(isLoading: true);
      final loaded = loading.copyWith(settings: _shop(), isLoading: false);

      expect(loading.isLoading, true);
      expect(loaded.isLoading, false);
      expect(loaded.settings?.shopName, 'ESMS Electricals');
    });

    test('settings state preserves existing values while saving', () {
      final state = SettingsState(settings: _shop());
      final saving = state.copyWith(isSaving: true, clearError: true);

      expect(saving.settings?.currency, 'INR');
      expect(saving.isSaving, true);
      expect(saving.errorMessage, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:electrical_shop/features/auth/models/auth_validator.dart';
import 'package:electrical_shop/features/auth/models/setup_validator.dart';
import 'package:electrical_shop/shared/models/user_model.dart';

void main() {
  group('AuthValidator', () {
    test('validates required and formatted email', () {
      expect(AuthValidator.validateEmail(null), 'Email is required');
      expect(AuthValidator.validateEmail(''), 'Email is required');
      expect(
        AuthValidator.validateEmail('invalid'),
        'Enter a valid email address',
      );
      expect(AuthValidator.validateEmail('owner@example.com'), isNull);
    });

    test('validates required password', () {
      expect(AuthValidator.validatePassword(null), 'Password is required');
      expect(AuthValidator.validatePassword(''), 'Password is required');
      expect(AuthValidator.validatePassword('secret'), isNull);
    });
  });

  group('SetupValidator', () {
    test('validates required shop name', () {
      expect(SetupValidator.validateShopName(null), 'Shop name is required');
      expect(SetupValidator.validateShopName(' '), 'Shop name is required');
      expect(SetupValidator.validateShopName('ESMS Electricals'), isNull);
    });

    test('validates shop phone', () {
      expect(SetupValidator.validatePhone(null), 'Shop phone is required');
      expect(SetupValidator.validatePhone('abc'), 'Enter a valid phone number');
      expect(SetupValidator.validatePhone('+911234567890'), isNull);
    });

    test('validates shop email', () {
      expect(SetupValidator.validateEmail(null), 'Shop email is required');
      expect(
        SetupValidator.validateEmail('invalid'),
        'Enter a valid email address',
      );
      expect(SetupValidator.validateEmail('shop@example.com'), isNull);
    });
  });

  group('Authentication profile state', () {
    final date = DateTime(2026, 9, 3);

    UserModel profile({bool active = true}) {
      return UserModel(
        uid: 'user-1',
        name: 'Owner',
        email: 'owner@example.com',
        phone: '1234567890',
        role: UserRole.owner,
        isActive: active,
        createdAt: date,
        updatedAt: date,
      );
    }

    test('active profile is eligible for dashboard access', () {
      expect(profile().isActive, isTrue);
    });

    test('inactive profile is not eligible for dashboard access', () {
      expect(profile(active: false).isActive, isFalse);
    });
  });
}

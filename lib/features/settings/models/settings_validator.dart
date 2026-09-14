import '../../../shared/models/shop_model.dart';

class SettingsValidator {
  SettingsValidator._();

  static String? validateShopName(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Shop name is required'
        : null;
  }

  static String? validateEmail(String? value) {
    if (value == null) return 'Shop email is required';
    final email = value.trim();
    if (email.isEmpty) return 'Shop email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null) return 'Shop phone is required';
    final phone = value.trim();
    if (phone.isEmpty) return 'Shop phone is required';
    if (!RegExp(r'^[0-9+()\-\s]{7,20}$').hasMatch(phone)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validatePrefix(String? value, String label) {
    if (value == null) return '$label is required';
    if (value.trim().isEmpty) return '$label is required';
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value.trim())) {
      return '$label may contain letters, numbers, hyphens, and underscores';
    }
    return null;
  }

  static String? validateShop(ShopModel shop) {
    return validateShopName(shop.shopName) ??
        validateEmail(shop.email) ??
        validatePhone(shop.phone) ??
        validatePrefix(shop.billPrefix, 'Bill prefix') ??
        validatePrefix(shop.purchaseOrderPrefix, 'Purchase order prefix');
  }
}

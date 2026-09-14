class SetupValidator {
  SetupValidator._();

  static String? validateShopName(String? value) {
    return value?.trim().isNotEmpty == true ? null : 'Shop name is required';
  }

  static String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Shop phone is required';
    if (!RegExp(r'^[0-9+()\-\s]{7,20}$').hasMatch(phone)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Shop email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }
}

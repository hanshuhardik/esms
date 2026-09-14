class SupplierValidator {
  SupplierValidator._();

  static String? validateName(String? value) {
    return value?.trim().isNotEmpty == true
        ? null
        : 'Supplier name is required';
  }

  static String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone is required';
    if (!RegExp(r'^[0-9+()\-\s]{7,20}$').hasMatch(phone)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? null
        : 'Enter a valid email address';
  }
}

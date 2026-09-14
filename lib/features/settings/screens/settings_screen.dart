import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/shop_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../staff/models/authorization.dart';
import '../../staff/models/permission.dart';
import '../models/settings_validator.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _billPrefixController = TextEditingController();
  final _purchasePrefixController = TextEditingController();
  String? _loadedSettingsId;
  bool _gstEnabled = false;
  String _currency = 'INR';

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _billPrefixController.dispose();
    _purchasePrefixController.dispose();
    super.dispose();
  }

  void _populate(ShopModel settings) {
    if (_loadedSettingsId == settings.id &&
        _shopNameController.text == settings.shopName) {
      return;
    }
    _loadedSettingsId = settings.id;
    _shopNameController.text = settings.shopName;
    _phoneController.text = settings.phone;
    _emailController.text = settings.email;
    _addressController.text = settings.address;
    _billPrefixController.text = settings.billPrefix;
    _purchasePrefixController.text = settings.purchaseOrderPrefix;
    _gstEnabled = settings.gstEnabled;
    _currency = settings.currency;
  }

  Future<void> _save(ShopModel settings, currentUser) async {
    if (!_formKey.currentState!.validate()) return;
    final updated = settings.copyWith(
      shopName: _shopNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      gstEnabled: _gstEnabled,
      currency: _currency,
      billPrefix: _billPrefixController.text.trim(),
      purchaseOrderPrefix: _purchasePrefixController.text.trim(),
    );

    final saved = await ref
        .read(settingsProvider.notifier)
        .updateSettings(settings: updated, currentUser: currentUser);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Settings saved successfully' : 'Unable to save settings',
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await ref.read(authProvider.notifier).sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send password reset email')),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final currentUser = authState.valueOrNull;
    final settings = settingsState.settings;

    if (settings != null) _populate(settings);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsState.isLoading && settings == null
          ? const LoadingWidget(message: 'Loading settings...')
          : settings == null
          ? _ErrorState(
              message: settingsState.errorMessage ?? 'Settings unavailable',
              onRetry: () => ref.read(settingsProvider.notifier).loadSettings(),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(settingsProvider.notifier).loadSettings(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionTitle(title: 'Shop'),
                  Form(
                    key: _formKey,
                    child: _ShopForm(
                      settings: settings,
                      canEdit:
                          currentUser != null &&
                          Authorization.can(
                            currentUser,
                            Permission.manageSettings,
                          ),
                      shopNameController: _shopNameController,
                      phoneController: _phoneController,
                      emailController: _emailController,
                      addressController: _addressController,
                      billPrefixController: _billPrefixController,
                      purchasePrefixController: _purchasePrefixController,
                      gstEnabled: _gstEnabled,
                      currency: _currency,
                      onGstChanged: (value) =>
                          setState(() => _gstEnabled = value),
                      onCurrencyChanged: (value) =>
                          setState(() => _currency = value ?? 'INR'),
                      onSave: currentUser == null
                          ? null
                          : () => _save(settings, currentUser),
                      isSaving: settingsState.isSaving,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Account'),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(currentUser?.name ?? 'Signed-in user'),
                          subtitle: Text(
                            currentUser?.email ??
                                'Account information unavailable',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock_reset_outlined),
                          title: const Text('Reset password'),
                          subtitle: const Text('Send a password reset email'),
                          onTap: currentUser == null
                              ? null
                              : () => _sendPasswordReset(currentUser.email),
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Sign out'),
                          onTap: _signOut,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'App'),
                  Card(
                    child: const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('ESMS'),
                      subtitle: Text('Electrical Shop Management System'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ShopForm extends StatelessWidget {
  final ShopModel settings;
  final bool canEdit;
  final TextEditingController shopNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController billPrefixController;
  final TextEditingController purchasePrefixController;
  final bool gstEnabled;
  final String currency;
  final ValueChanged<bool> onGstChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final VoidCallback? onSave;
  final bool isSaving;

  const _ShopForm({
    required this.settings,
    required this.canEdit,
    required this.shopNameController,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.billPrefixController,
    required this.purchasePrefixController,
    required this.gstEnabled,
    required this.currency,
    required this.onGstChanged,
    required this.onCurrencyChanged,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _field(
          shopNameController,
          'Shop name',
          SettingsValidator.validateShopName,
        ),
        _field(
          phoneController,
          'Shop phone',
          SettingsValidator.validatePhone,
          keyboardType: TextInputType.phone,
        ),
        _field(
          emailController,
          'Shop email',
          SettingsValidator.validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        _field(addressController, 'Shop address', null, maxLines: 3),
        _field(
          billPrefixController,
          'Bill prefix',
          (value) => SettingsValidator.validatePrefix(value, 'Bill prefix'),
        ),
        _field(
          purchasePrefixController,
          'Purchase order prefix',
          (value) =>
              SettingsValidator.validatePrefix(value, 'Purchase order prefix'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('GST enabled'),
          value: gstEnabled,
          onChanged: canEdit ? onGstChanged : null,
        ),
        DropdownButtonFormField<String>(
          initialValue: currency,
          decoration: const InputDecoration(labelText: 'Currency'),
          items: const [
            DropdownMenuItem(value: 'INR', child: Text('INR')),
            DropdownMenuItem(value: 'USD', child: Text('USD')),
            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
          ],
          onChanged: canEdit ? onCurrencyChanged : null,
        ),
        if (!canEdit)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Only authorized users can modify shop settings.'),
            ),
          ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'Save settings',
          onPressed: canEdit ? onSave : null,
          isLoading: isSaving,
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?)? validator, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: canEdit,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
